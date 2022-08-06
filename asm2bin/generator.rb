require 'stringio'

module ASM2Bin
  # Class responsive of generating code out of a program
  class Generator
    # Create a new generator
    # @param dont_pad [Boolean] tell if the output file shouldn't be padded
    # @param output_to_memory [Boolean] tell if the data should be output to memory
    def initialize(dont_pad: false, output_to_memory: false)
      @dont_pad = dont_pad
      @output_to_memory = output_to_memory ? {} : nil
    end

    # Generate the program
    # @param program [Sem::Program]
    # @param program_name [String]
    # @return [Hash, nil]
    def generate(program, program_name)
      generate_pram(program, "#{program_name}.pram.bin")
      generate_roms(program, program_name)
      return @output_to_memory
    end

    private

    # Generate the PRAM data
    # @param program [Sem::Program]
    # @param filename [String]
    def generate_pram(program, filename)
      data = program.instructions.map do |instruction|
        bytecode = instruction.high | instruction.low
        next (bytecode << 8) | instruction.rest if instruction.size == 1

        next [(bytecode << 8) | instruction.rest, *instruction.extra]
      end.flatten # Not using flatmap because bad type inference
      # Pad data with nop
      data.fill(0b001_00000_0000_0000, data.size...0x1_0000) unless @dont_pad

      if @output_to_memory
        @output_to_memory[filename] = data.pack('S>*')
      else
        File.binwrite(filename, data.pack('S>*'))
      end
    end

    # Generate all the ROM
    # @param program [Sem::Program]
    # @param program_name [String]
    def generate_roms(program, program_name)
      rom_by_bank = group_rom_per_bank(program)
      rom_by_bank.each { |bank| generate_rom_bank(program_name, bank) }
    end

    # @param program [Sem::Program]
    # @return [Array<Array<Sem::ROMData>>]
    def group_rom_per_bank(program)
      return program.resources.group_by(&:rom_bank).values
    end

    # @param program_name [String]
    # @param bank [Array<Sem::ROMData>]
    def generate_rom_bank(program_name, bank)
      rom_bank = bank.first.rom_bank
      io = StringIO.new('', 'wb')
      bank.each do |data|
        io.pos = data.address * 2
        io.write(data.data)
      end
      file_data = io.string
      file_data << "\x00" * (0x2_0000 - file_data.bytesize) unless @dont_pad

      filename = "#{program_name}.rom.#{rom_bank}.bin"
      if @output_to_memory
        @output_to_memory[filename] = file_data
      else
        File.binwrite(filename, file_data)
      end
    end
  end
end
