# frozen_string_literal: true

module Interpreter
  # Class helping to decode the instructions from the CPU
  class InstructionDecoder
    # Pack format of the unsigned integer in CPU memory
    PACK_FORMAT = 'S>'
    # Pack format of the signed integer in CPU memory
    PACK_FORMAT_SIGNED = 's>'
    # List of decoding function by high bits
    DECODERS = [
      :decode_reg_p_reg, # 000 0
      :decode_val, # 000 1
      :decode_special, # 001 0 NOP / DmaCopy
      :decode_unknown, # 001 1
      :decode_reg_val, # 010 0
      :decode_reg, # 010 1
      :decode_reg_reg, # 011 0
      :decode_unknown, # 011 1
      :decode_p_val_val, # 100 0
      :decode_p_val, # 100 1
      :decode_p_val_reg, # 101 0
      :decode_unknown, # 101 1
      :decode_reg_p_val, # 110 0
      :decode_p_reg, # 110 1
      :decode_p_reg_reg, # 111 0
      :decode_unknown # 111 1
    ]
    # List of registers
    REGISTERS = %i[r0 r1 r2 r3 r4 r5 r6 r7 currentDmaId copyDataSize copyDataSrcAddr copyDataDestAddr pc st hp copyDataDmaDest]
    # List of instruction for 2 operands
    INSTRUCTION_2O = %i[mov or and xor add sub mul shr shl ror rol test cmp unk unk unk]
    # List of instruction for 1 operands
    INSTRUCTION_1O = %i[jc jnc jh jnh jl jnl jz jnz inv inc dec poll sync lock unlock jmp]
    # List of special instructions
    INSTRUCTION_SPE = %i[nop dmaCopy unk unk unk unk unk unk unk unk unk unk unk unk unk unk]

    # Get the current instruction size (to move pc forward)
    # @return [Integer]
    attr_reader :instruction_size

    # Get the current instruction
    # @return [Symbol]
    attr_reader :instruction

    # Get the left operand
    # @return [Integer, Symbol] (symbol = register)
    attr_reader :left

    # Get if left operand is pointer
    # @return [Boolean]
    attr_reader :is_left_pointer

    # Get the right operand
    # @return [Integer, Symbol] (symbol = register)
    attr_reader :right

    # Get if right operand is pointer
    # @return [Boolean]
    attr_reader :is_right_pointer

    # Create a new instruction decoder
    # @param pram [DMA]
    # @param registers [CpuRAM]
    def initialize(pram, registers)
      @pram = pram
      @registers = registers
      @instruction_size = 0
      @instruction = :nop
      @left = 0
      @right = 0
      @is_left_pointer = false
      @is_right_pointer = false
    end

    # Decode the current instruction
    def decode
      @pc = @registers.register_uint(:pc)
      @op = @pram.read(@pc * 2, 2).unpack1(PACK_FORMAT)
      send(DECODERS[@op >> 12], (@op >> 8) & 0xF)
    end

    private

    # Get left value (4bits)
    # @return [Integer]
    def left4
      return (@op >> 4) & 0xF
    end

    # Get the right value (4bits)
    # @return [Integer]
    def right4
      return @op & 0xF
    end

    # Get the left value (16bits)
    # @return [Integer]
    def left16
      return @pram.read(@pc * 2 + 2, 2).unpack1(PACK_FORMAT_SIGNED)
    end

    # Get the right value (16bits)
    # @return [Integer]
    def right16
      return @pram.read(@pc * 2 + 4, 2).unpack1(PACK_FORMAT_SIGNED)
    end

    # Decode unknown instruction
    # @param op_code [Integer] instruction designated by the instruction
    def decode_unknown(op_code)
      raise "Tried to decode unknown instruction #{op.to_s(16)} at #{@pc}"
    end

    # Decode int reg, [reg]
    # @param op_code [Integer] instruction designated by the instruction
    def decode_reg_p_reg(op_code)
      @instruction_size = 1
      @left = REGISTERS[left4]
      @is_left_pointer = false
      @right = REGISTERS[right4]
      @is_right_pointer = true
      @instruction = INSTRUCTION_2O[op_code]
    end

    # Decode int val
    # @param op_code [Integer] instruction designated by the instruction
    def decode_val(op_code)
      @instruction_size = 2
      @left = left16
      @is_left_pointer = false
      @right = 0
      @is_right_pointer = false
      @instruction = INSTRUCTION_1O[op_code]
    end

    # Decode int
    # @param op_code [Integer] instruction designated by the instruction
    def decode_special(op_code)
      @instruction_size = 1
      @left = 0
      @is_left_pointer = false
      @right = 0
      @is_right_pointer = false
      @instruction = INSTRUCTION_SPE[op_code]
    end

    # Decode int reg, val
    # @param op_code [Integer] instruction designated by the instruction
    def decode_reg_val(op_code)
      @instruction_size = 2
      @left = REGISTERS[right4]
      @is_left_pointer = false
      @right = left16
      @is_right_pointer = false
      @instruction = INSTRUCTION_2O[op_code]
    end

    # Decode int reg
    # @param op_code [Integer] instruction designated by the instruction
    def decode_reg(op_code)
      @instruction_size = 1
      @left = REGISTERS[right4]
      @is_left_pointer = false
      @right = 0
      @is_right_pointer = false
      @instruction = INSTRUCTION_1O[op_code]
    end

    # Decode int reg, reg
    # @param op_code [Integer] instruction designated by the instruction
    def decode_reg_reg(op_code)
      @instruction_size = 1
      @left = REGISTERS[left4]
      @is_left_pointer = false
      @right = REGISTERS[right4]
      @is_right_pointer = false
      @instruction = INSTRUCTION_2O[op_code]
    end

    # Decode int [val], val
    # @param op_code [Integer] instruction designated by the instruction
    def decode_p_val_val(op_code)
      @instruction_size = 3
      @left = left16
      @is_left_pointer = true
      @right = right16
      @is_right_pointer = false
      @instruction = INSTRUCTION_2O[op_code]
    end

    # Decode int [val]
    # @param op_code [Integer] instruction designated by the instruction
    def decode_p_val(op_code)
      @instruction_size = 2
      @left = right16
      @is_left_pointer = true
      @right = 0
      @is_right_pointer = false
      @instruction = INSTRUCTION_1O[op_code]
    end

    # Decode int [val], reg
    # @param op_code [Integer] instruction designated by the instruction
    def decode_p_val_reg(op_code)
      @instruction_size = 2
      @left = left16
      @is_left_pointer = true
      @right = REGISTERS[right4]
      @is_right_pointer = false
      @instruction = INSTRUCTION_2O[op_code]
    end

    # Decode int reg, [val]
    # @param op_code [Integer] instruction designated by the instruction
    def decode_reg_p_val(op_code)
      @instruction_size = 2
      @left = REGISTERS[right4]
      @is_left_pointer = false
      @right = left16
      @is_right_pointer = true
      @instruction = INSTRUCTION_2O[op_code]
    end

    # Decode int [reg]
    # @param op_code [Integer] instruction designated by the instruction
    def decode_p_reg(op_code)
      @instruction_size = 1
      @left = REGISTERS[right4]
      @is_left_pointer = true
      @right = 0
      @is_right_pointer = false
      @instruction = INSTRUCTION_1O[op_code]
    end

    # Decode int [reg], reg
    # @param op_code [Integer] instruction designated by the instruction
    def decode_p_reg_reg(op_code)
      @instruction_size = 1
      @left = REGISTERS[left4]
      @is_left_pointer = true
      @right = REGISTERS[right4]
      @is_right_pointer = false
      @instruction = INSTRUCTION_2O[op_code]
    end
  end
end
