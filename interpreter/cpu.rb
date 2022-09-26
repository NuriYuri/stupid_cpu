# frozen_string_literal: true

require_relative 'dma/dma'
require_relative 'dma/cpu_ram'
require_relative 'dma/vram1'
require_relative 'helpers/terminal'
require_relative 'instruction_decoder'

module Interpreter
  # Class representing the CPU running the program
  #
  # @note this version is badly implemented (just want to see some stuff quick)
  class CPU
    # Get the instruction decoder
    # @return [InstructionDecoder]
    attr_reader :decoder

    def initialize(program_path)
      init_cpu_memory
      init_north_bridge
      load_program(program_path)
      @decoder = InstructionDecoder.new(@pram, @registers)
    end

    private

    def init_cpu_memory
      @pram = DMA.new(200_000_000) # 200 MHz
      @registers = CpuRAM.new(DMA.new(200_000_000, 4), DMA.new(200_000_000, 4))
    end

    def init_north_bridge
      @north_bridge = [
        @registers,
        @pram,
        *(4.times.map { DMA.new(2_000_000) })
      ]
      terminal = TerminalHelper.new
      terminal.title = 'CPU test'
      @north_bridge[16] = VRAM1.new(terminal)
    end

    def load_program(program_path)
      pram = File.binread("#{program_path}.pram.bin")
      @pram.write(0, pram)
      Dir["#{program_path}.rom.*.bin"].each do |rom_filename|
        rom_id = rom_filename.match(/([0-9]+).bin$/).captures[0].to_i
        rom = DMA.new(1_000_000)
        rom.write(0, File.binread(rom_filename))
        @north_bridge[64 + rom_id] = rom
      end
    end
  end
end
