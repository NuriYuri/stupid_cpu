# frozen_string_literal: true

module Interpreter
  # Class describing the first VRAM (responsive of text display)
  # @note this class is purposely not customizable using inheritance or monkey-patch
  class VRAM1 < DMA
    # Regexp matching the control character so we stop displaying when those character are met
    CONTROL_CHARACTERS = /[\x00-\x1F]/
    # Create the new VRAM allowing text display
    # @param terminal [TerminalHelper]
    def initialize(terminal)
      super(80 * 24 * 5 * 75) # 80x24 * (4 + 1) for text+attributes, * 75 for refresh rate
      @terminal = terminal
      # @type [Array<Integer>]
      @line_addresses = 24.times.map { |i| i * 320 } # 80 * 4
      # @type [Array<Integer>]
      @attributes_addresses = 24.times.map { |i| 7680 + i * 80 }
      @current_attribute_address = 0xFFFC << 1
      @cursor_x_address = 0xFFFD << 1
      @cursor_y_address = 0xFFFE << 1
      @memory_mode_address = 0xFFFF << 1
      @displaying_text = true
      # Set default attribute to light gray
      @memory.pos = 0xFFFC << 1 | 1
      @memory.write("\x07")
    end

    # Write the data to the DMA
    # @param address [Integer] address where data will be located (in bytes)
    # @param data [String] data to write
    def write(address, data)
      data.force_encoding(Encoding::BINARY)
      data_range = address...(address + data.bytesize)
      if data_range.include?(@memory_mode_address)
        write_memory_mode(@memory_mode_address, data[@memory_mode_address - address, 2])
        unless @displaying_text
          dma_write(address, data)
          return
        end
      end
      # No change in memory mode we display the text as normal
      write_process(address, data, data_range)
      reset_cursor_position
    end

    private

    # Write the memory mode data
    # @param address [Integer]
    # @param data [String]
    def write_memory_mode(address, data)
      dma_write(address, data)
      new_mode = dma_read(@memory_mode_address, 2).unpack1('S>')
      last_mode = @displaying_text
      @displaying_text = new_mode == 0
      return if last_mode == @displaying_text

      return @displaying_text ? redraw_whole_screen : clear_screen
    end

    # Write the memory mode data
    # @param address [Integer]
    # @param data [String]
    # @param data_range [Range]
    def write_process(address, data, data_range)
      # Select all lines affected by data range
      line_indexes = @line_addresses.each_index.select do |i|
        next data_range.include?(@line_addresses[i]) || data_range.include?((@line_addresses[i + 1] || 7680) - 1)
      end
      # Write all the line affected by data range
      line_indexes.each do |i|
        write_line(address, data, i)
      end
      # Write rest of data starting of attribute addresses
      new_address = [data_range.begin, @attributes_addresses.first].max
      if data.bytesize > new_address - address
        dma_write(new_address, data[new_address - address, data.bytesize])
        # Rewrite line affected by attribute change
        @attributes_addresses.select { |attribute_address| data_range.include?(attribute_address) }.each_index do |i|
          draw_whole_line(i)
        end
      end
    end

    # Write the memory mode data
    # @param address [Integer]
    # @param data [String]
    # @param line_index [Integer]
    def write_line(address, data, line_index)
      line_address = @line_addresses[line_index]
      current_attribute = dma_read(@current_attribute_address, 2).unpack1('S>') & 0xFF
      # If we're not writing from beginning of the line
      if address > line_address
        # Get data to write on current line (address...next_line_address)
        next_line_address = @line_addresses[line_index + 1] || 7680
        new_data = data[0, next_line_address - address]
        # Retrieve old data to know where to start writing attribute data
        old_data = dma_read(line_address, address - line_address).force_encoding(Encoding::UTF_8)
        data_size = new_data.force_encoding(Encoding::UTF_8).size.clamp(0, 80) - old_data.size
        # Write attribute data if any
        dma_write(@attributes_addresses[line_index] + old_data.size, current_attribute.chr * data_size) if data_size > 0
        # Write text data
        dma_write(address, new_data)
      else
        # Get data to write on current line
        new_data = data[line_address - address, 320]
        # Get how much attribute to write on attribute memory
        data_size = new_data.force_encoding(Encoding::UTF_8).size.clamp(0, 80)
        dma_write(@attributes_addresses[line_index], current_attribute.chr * data_size)
        # Write text data
        dma_write(line_address, new_data)
      end
      draw_whole_line(line_index)
    end

    # Clear the screen
    def clear_screen
      @terminal.reset_color
      @terminal.clear
    end

    # Redraw the whole screen
    def redraw_whole_screen
      @terminal.hide_cursor
      24.times { |i| draw_whole_line(i) }
      reset_cursor_position
    end

    # Draw a whole line
    # @param i [Integer] index of the line
    def draw_whole_line(i)
      @terminal.set_cursor_position(0, i + 1) # y = 0 => line = 1 in terminal emulation
      text_data = dma_read(@line_addresses[i], 320).force_encoding(Encoding::UTF_8)
      text_size = (text_data.index(CONTROL_CHARACTERS) || 80).clamp(0, 80)
      text_data = text_data[0, text_size]# << ' ' # .ljust(80, ' ')
      # text_size += 2 if text_size < 80
      # @type [Array]
      attribute_data = dma_read(@attributes_addresses[i], 80).each_byte.to_a
      position = 0
      while position < text_size
        # Find the number of character to draw
        current_attribute = attribute_data.first || 0
        size_with_same_attributes = attribute_data.find_index { |a| a != current_attribute } || 1
        # Reducing attribute data size so next time we have correct data
        attribute_data.shift(size_with_same_attributes)
        # Getting the text to display
        text = text_data[position, size_with_same_attributes]
        # Draw & go to next iteration
        display_text_to_terminal(text, current_attribute)
        position += size_with_same_attributes
      end
      @terminal.clear_rest_of_the_line
    end

    # Display a text to the terminal
    # @param text [String]
    # @param attribute [Integer]
    def display_text_to_terminal(text, attribute)
      id_color = attribute & 0b000_0_111
      id_background = (attribute & 0b111_0_000) >> 4
      @terminal.set_color_with_background(id_color, id_background, is_light: attribute.anybits?(0b000_1_000))
      @terminal.write(text)
    end

    # Reset the cursor position to the right position in the screen
    def reset_cursor_position
      cursor_x = dma_read(@cursor_x_address, 2).unpack1('S>')
      cursor_y = dma_read(@cursor_x_address, 2).unpack1('S>')
      if cursor_x > 80 || cursor_y > 24
        @terminal.hide_cursor
      else
        @terminal.set_cursor_position(cursor_x, cursor_y + 1)
        @terminal.show_cursor
      end
    end
  end
end
