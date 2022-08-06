# frozen_string_literal: true

module ASM2Bin
  # Class responsive of making more sense out of the instructions, labels & symbols
  class Sem
    # Parse a program
    # @param ast_program [AST::Program]
    # @return [Sem::Program]
    def parse(ast_program)
      return Program.new(ast_program)
    end

    # Class describing a program that make sense
    class Program
      # List of DMA related instructions
      DMA_INSTRUCTIONS = %i[poll sync lock unlock]
      # All the labels pointing to an instructions address
      # @return [Hash{ Symbol => Integer }]
      attr_reader :labels

      # All the symbols pointing to data in the memory
      # @return [Hash{ Symbol => ROMData }]
      attr_reader :symbols

      # All the resources for the program
      # @return [Array<ROMData>]
      attr_reader :resources

      # All the instructions of this program
      # @return [Array<AST::Instruction>]
      attr_reader :instructions

      # Create a new program
      # @param program [AST::Program]
      def initialize(program)
        @labels = process_labels(program.labels, program.instructions)
        @symbols, @resources = process_resources(program.symbols)
        @instructions = process_instructions(program.instructions)
      end

      private

      # Function that computes the label address in program memory
      # @param labels [Hash{ Symbol => Integer }]
      # @param instructions [Array<AST::Instruction>]
      # @return [Hash{ Symbol => Integer }]
      def process_labels(labels, instructions)
        instruction_addresses = instructions.map(&:size).reduce([0]) { |prev, curr| prev.push(curr + prev.last) }

        return labels.transform_values { |v| instruction_addresses[v] || 0 }
      end

      # Function that process the program resources
      # @param symbols [Hash]
      # @return [Array(Hash, Array<ROMData>)]
      def process_resources(symbols)
        all_resources = []

        new_symbols = symbols.transform_values do |v|
          rom_data = ROMData.new(v, all_resources)
          all_resources << rom_data
          next rom_data
        end

        return new_symbols, all_resources
      end

      # Function that process the instructions
      # @param instructions [Array<AST::Instruction>]
      # @return [Array<AST::Instruction>]
      def process_instructions(instructions)
        return instructions.map do |instruction|
          next process_move_instruction(instruction) if instruction.type == :mov
          next process_dma_instruction(instruction) if DMA_INSTRUCTIONS.include?(instruction.type)
          next process_2_operand_instruction(instruction) if instruction.is_a?(AST::Instruction::WithValues)
          next process_1_operand_instruction(instruction) if instruction.is_a?(AST::Instruction::WithValue)

          next instruction
        end
      end

      # Function that process the instructions
      # @param instruction [AST::Instruction::WithValues]
      # @return [Array<AST::Instruction::WithValues>]
      def process_move_instruction(instruction)
        return instruction if instruction.left.is_a?(Integer) && instruction.right.is_a?(Integer)

        instruction = instruction.clone
        if instruction.is_left_register
          return instruction unless instruction.right.is_a?(Symbol)

          case instruction.left
          when 8, 0xF
            instruction.instance_variable_set(:@right, find_symbol_address(instruction.right, is_dma: true))
          when 9
            instruction.instance_variable_set(:@right, find_symbol_address(instruction.right, is_size: true))
          else
            instruction.instance_variable_set(:@right, find_symbol_address(instruction.right))
          end
        else
          instruction.instance_variable_set(:@left, find_symbol_address(instruction.left)) if instruction.left.is_a?(Symbol)
          instruction.instance_variable_set(:@right, find_symbol_address(instruction.right)) if instruction.right.is_a?(Symbol)
        end
        return instruction
      end

      # Function that process the instructions
      # @param instruction [AST::Instruction::WithValue]
      # @return [Array<AST::Instruction::WithValue>]
      def process_dma_instruction(instruction)
        return instruction unless instruction.left.is_a?(Symbol)

        instruction = instruction.clone
        instruction.instance_variable_set(:@left, find_symbol_address(instruction.left, is_dma: true))
        return instruction
      end

      # Function that process the instructions
      # @param instruction [AST::Instruction::WithValue]
      # @return [Array<AST::Instruction::WithValue>]
      def process_1_operand_instruction(instruction)
        return instruction unless instruction.left.is_a?(Symbol)

        instruction = instruction.clone
        instruction.instance_variable_set(:@left, find_symbol_address(instruction.left))
        return instruction
      end

      # Function that process the instructions
      # @param instruction [AST::Instruction::WithValues]
      # @return [Array<AST::Instruction::WithValues>]
      def process_2_operand_instruction(instruction)
        return instruction if instruction.left.is_a?(Integer) && instruction.right.is_a?(Integer)

        instruction = instruction.clone
        instruction.instance_variable_set(:@left, find_symbol_address(instruction.left)) if instruction.left.is_a?(Symbol)
        instruction.instance_variable_set(:@right, find_symbol_address(instruction.right)) if instruction.right.is_a?(Symbol)
        return instruction
      end

      # Function that finds the address of a symbol
      # @param symbol [Symbol]
      # @param is_dma [Boolean] if the requested address expect the DMA id instead
      # @param is_size [Boolean] if the requested address expect the data size instead
      # @return [Integer]
      def find_symbol_address(symbol, is_dma: false, is_size: false)
        label = @labels[symbol]
        return label if label

        rom_data = symbols[symbol]
        return rom_data.data.bytesize / 2 if is_size

        return is_dma ? rom_data.rom_bank + 64 : rom_data.address
      end
    end

    # Class describing data in the rom bank
    class ROMData
      # Get the rom bank the data is stored into
      # @return [Integer]
      attr_reader :rom_bank

      # Get the address of the data in the ROM bank (in words of 16bits)
      # @return [Integer]
      attr_reader :address

      # Get the data to write into the ROM bank
      # @return [String]
      attr_reader :data

      # Create a new ROM Bank object
      # @param data [String, Integer, Float, Symbol]
      # @param all_resources [Array<ROMData>]
      def initialize(data, all_resources)
        @data = convert_data(data)
        @rom_bank, @address = find_memory_location(all_resources)
      end

      private

      # Function responsive of finding the memory location of the data
      # @param all_resources [Array<ROMData>]
      # @return [Array<Integer>]
      def find_memory_location(all_resources)
        last_resource = all_resources[-1]
        return 0, 0 unless last_resource

        rom_bank = last_resource.rom_bank
        address = last_resource.address + last_resource.data.bytesize / 2
        data_size = @data.bytesize / 2
        return rom_bank + 1, 0 if (address + data_size) > 0x1_0000

        return rom_bank, address
      end

      # Function responsive of converting data to a string value
      # @param data [Object]
      # @return [String]
      def convert_data(data)
        case data
        when Integer
          return convert_integer(data)
        when Float
          return [data].pack('f')
        when String
          return pad(convert_string(data))
        when Symbol
          return pad(data.to_s)
        else
          raise "Unsupported data type #{data.class}"
        end
      end

      # Pad the data to ensure its always block of 16bits
      # @param data [String]
      # @return [String]
      def pad(data)
        return data << "\x00" if data.bytesize.odd?

        return data
      end

      # Convert an integer to data
      # @param data [Integer]
      # @return [String]
      def convert_integer(data)
        return data >= 0 ? convert_positive_integer(data) : convert_negative_integer(data)
      end

      # Convert a positive integer
      # @param data [Integer]
      # @return [String]
      def convert_positive_integer(data)
        if data & 0xFFFF == data
          return [data].pack('S>')
        elsif data & 0xFFFF_FFFF == data
          return [data].pack('I>')
        elsif data & 0xFFFF_FFFF_FFFF_FFFF == data
          return [data].pack('Q>')
        else
          raise "Integer #{data} is too big"
        end
      end

      # Convert a negative integer
      # @param data [Integer]
      # @return [String]
      def convert_negative_integer(data)
        if data >= ~0x7FFF
          return [data].pack('s>')
        elsif data >= ~0x7FFF_FFFF
          return [data].pack('i>')
        elsif data >= ~0x7FFF_FFFF_FFFF_FFFF
          return [data].pack('q>')
        else
          raise "Integer #{data} is too big"
        end
      end

      # Convert a string to string data
      # @param data [String]
      # @return [String]
      def convert_string(data)
        if data.start_with?('file://')
          file_data = File.binread(filename = data[7..])
          raise "File #{filename} is too big (size=#{file_data.bytesize},max=131072)" if file_data.bytesize > 0x2_0000

          return file_data
        else
          return data
        end
      end
    end
  end
end
