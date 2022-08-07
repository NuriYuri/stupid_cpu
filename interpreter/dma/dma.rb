require 'stringio'

# Module holding the stupid cpu binary interpreter and some components connected to that cpu
module Interpreter
  # Class abstracting a DMA
  class DMA < Mutex
    # Create a new DMA
    # @param memory_speed [Integer] speed of the memory (in bytes / seconds)
    # @param memory_size [Integer, String] size of the memory or initial memory data
    def initialize(memory_speed, memory_size = 0x2_0000)
      super()
      @memory_speed = memory_speed.to_f
      @memory_size = memory_size.is_a?(String) ? memory_size.bytesize : memory_size
      @memory = StringIO.new(memory_size.is_a?(String) ? memory_size : "\x00" * memory_size, 'r+b')
    end

    # Get the time it takes to read/write the data of a specific size
    # @param size [Integer] size of the data to read/write (in bytes)
    # @return [Float] time it actually take to transfer that data
    def transfer_speed(size)
      return size / @memory_speed
    end

    # Read data from the DMA
    # @param address [Integer] address where data is located (in bytes)
    # @param size [Integer] size of the data to read (in bytes)
    # @return [String]
    def read(address, size)
      return '' if address >= @memory_size || address < 0

      actual_size = (address + size).clamp(0, @memory_size) - address
      @memory.pos = address
      return @memory.read(actual_size) || ''
    end
    alias dma_read read
    private :dma_read

    # Write the data to the DMA
    # @param address [Integer] address where data will be located (in bytes)
    # @param data [String] data to write
    def write(address, data)
      return nil if address >= @memory_size || address < 0

      size = data.bytesize
      actual_size = (address + size).clamp(0, @memory_size) - address
      @memory.pos = address
      @memory.write(data[0, actual_size])
      return nil
    end
    alias dma_write write
    private :dma_write

    # Copy data from another DMA
    # @param dma [DMA]
    # @param source_address [Integer] address where data is located (in bytes)
    # @param source_size [Integer] size of the data in other dma (in bytes)
    # @param dest_address [Integer] address where data will be located (in bytes)
    def copy_data_from(dma, source_address, source_size, dest_address)
      dma.synchronize do
        synchronize do
          # @type [String]
          data_from_dma = nil
          delta = operate_and_get_delta { data_from_dma = dma.read(source_address, source_size) }
          break if data_from_dma.bytesize == 0

          # @type [Float]
          time_to_wait = [dma.transfer_speed(data_from_dma.bytesize), transfer_speed(data_from_dma.bytesize)].max - delta
          delta = operate_and_get_delta { write(dest_address, data_from_dma) }
          time_to_wait -= delta
          sleep(time_to_wait) if time_to_wait > 0
        end
      end
    end

    private

    # Perform an operation and get the time it took
    # @yield Block to execute
    # @return [Float] time the operation took
    def operate_and_get_delta
      t = Time.new
      yield
      return Time.new - t
    end
  end
end
