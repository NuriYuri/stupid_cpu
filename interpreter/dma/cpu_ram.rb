# frozen_string_literal: true

module Interpreter
  # Class describing the CPU memory
  class CpuRAM < DMA
    # Address mapping of the CPU memory
    ADDRESS_MAPPING = {
      r0: 0,
      r1: 2,
      r2: 4,
      r3: 6,
      r4: 8,
      r5: 10,
      r6: 12,
      r7: 14,
      currentDmaId: 16,
      copyDataSize: 18,
      copyDataSrcAddr: 20,
      copyDataDestAddr: 22,
      pc: 24,
      st: 26,
      hp: 28,
      copyDataDmaDest: 30,
      gpIO1Flags: 32,
      gpIO2Flags: 34,
      gpIO1State: 36,
      gpIO2State: 38,
      gpIO1LastState: 40,
      gpIO2LastState: 42,
      year: 44,
      monthDay: 46,
      hourMinute: 48,
      seconds: 50,
      milliseconds: 52,
      ram: 65_536
    }
    # Pack format of the unsigned integer in CPU memory
    PACK_FORMAT = 'S>'
    # Pack format of the signed integer in CPU memory
    PACK_FORMAT_SIGNED = 's>'
    # Pack format of month day
    MD_PACK_FORMAT = 'CC'

    # Create a new CPU memory
    # @param gpio1 [DMA]
    # @param gpio2 [DMA]
    def initialize(gpio1, gpio2)
      super(200_000_000) # 200 MHz
      @gpio1 = gpio1
      @gpio2 = gpio2
    end

    # Read data from the DMA
    # @param address [Integer] address where data is located (in bytes)
    # @param size [Integer] size of the data to read (in bytes)
    # @return [String]
    def read(address, size)
      fix_memory(address, size)
      super
    end

    # Get a register data
    # @param name [Symbol]
    # @return [String]
    def register(name)
      return read(ADDRESS_MAPPING[name], 2)
    end

    # Get a register integer data
    # @param name [Symbol]
    # @return [Integer]
    def register_uint(name)
      return read(ADDRESS_MAPPING[name], 2).unpack1(PACK_FORMAT)
    end

    # Get a register signed integer data
    # @param name [Symbol]
    # @return [Integer]
    def register_int(name)
      return read(ADDRESS_MAPPING[name], 2).unpack1(PACK_FORMAT_SIGNED)
    end

    # Write a register integer data
    # @param name [Symbol]
    # @param data [Integer]
    def write_register_int(name, data)
      write(ADDRESS_MAPPING[name], [data].pack(PACK_FORMAT))
    end
    alias write_register_uint write_register_int

    private

    # Fix the memory before reading it
    # @param address [Integer] address where data is located (in bytes)
    # @param size [Integer] size of the data to read (in bytes)
    def fix_memory(address, size)
      span = address..(address + size)
      mapping = ADDRESS_MAPPING
      dma_write(mapping[:gpIO1State], fix_gpio(@gpio1.read(0, 2), :gpIO1Flags, :gpIO1State)) if span.include?(mapping[:gpIO1State])
      dma_write(mapping[:gpIO1LastState], fix_gpio(@gpio1.read(2, 2), :gpIO1Flags, :gpIO1LastState)) if span.include?(mapping[:gpIO1LastState])
      dma_write(mapping[:gpIO2State], fix_gpio(@gpio2.read(0, 2), :gpIO2Flags, :gpIO2State)) if span.include?(mapping[:gpIO2State])
      dma_write(mapping[:gpIO2LastState], fix_gpio(@gpio2.read(2, 2), :gpIO2Flags, :gpIO2LastState)) if span.include?(mapping[:gpIO2LastState])
      dma_write(mapping[:year], [(t ||= Time.now).year].pack(PACK_FORMAT)) if span.include?(mapping[:year])
      dma_write(mapping[:monthDay], [(t ||= Time.now).month, t.day].pack(MD_PACK_FORMAT)) if span.include?(mapping[:monthDay])
      dma_write(mapping[:hourMinute], [(t ||= Time.now).hour, t.min].pack(MD_PACK_FORMAT)) if span.include?(mapping[:hourMinute])
      dma_write(mapping[:seconds], [(t ||= Time.now).sec].pack(PACK_FORMAT)) if span.include?(mapping[:seconds])
      dma_write(mapping[:milliseconds], [(t || Time.now).usec / 1000].pack(PACK_FORMAT)) if span.include?(mapping[:milliseconds])
    end

    # Fix a GP IO value (read)
    # @param data [String]
    # @param flag_source [Symbol]
    # @param data_source [Symbol]
    # @return [String]
    def fix_gpio(data, flag_source, data_source)
      flags = dma_read(ADDRESS_MAPPING[flag_source], 2).unpack1(PACK_FORMAT)
      current_data = dma_read(ADDRESS_MAPPING[data_source], 2).unpack1(PACK_FORMAT)
      return [(data.unpack1(PACK_FORMAT) & flags) | (current_data & ~flags)].pack(PACK_FORMAT)
    end
  end
end
