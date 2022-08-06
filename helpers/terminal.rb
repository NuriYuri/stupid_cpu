# Helper allowing to manipulate terminal stuff
class TerminalHelper
  # Create a new Terminal Helper which manipulate a specific IO output
  # @param io [IO]
  def initialize(io = STDOUT)
    @io = io
  end

  # Write to the terminal
  # @param data [String]
  def write(data)
    @io.write(data)
  end

  # Puts to the terminal
  # @param data [String]
  def puts(data)
    @io.puts(data)
  end

  # Return to the beginning of the line
  def return_to_line_beginning
    @io.write("\r")
  end

  # Set the title of the Terminal
  # @param title [String]
  def title=(title)
    @io.write("\033]0;#{title}\007")
  end

  # Show the cursor
  def show_cursor
    @io.write("\033[?25h")
  end

  # Hide the cursor
  def hide_cursor
    @io.write("\033[?25l")
  end

  # Set the cursor position
  # @param x [Integer]
  # @param y [Integer]
  def set_cursor_position(x, y)
    @io.write("\033[#{y};#{x}H")
  end

  # Move the cursor up n lines
  # @param n [Integer]
  def move_cursor_up(n)
    @io.write("\033[#{n}A")
  end

  # Move the cursor down n lines
  # @param n [Integer]
  def move_cursor_down(n)
    @io.write("\033[#{n}B")
  end

  # Move the cursor forward n columns
  # @param n [Integer]
  def move_cursor_forward(n)
    @io.write("\033[#{n}C")
  end

  # Move the cursor backward n columns
  # @param n [Integer]
  def move_cursor_backward(n)
    @io.write("\033[#{n}D")
  end

  # Clear the terminal
  def clear
    @io.write("\033[2J")
  end

  # Clear all char from cursor pos to end of the line
  def clear_rest_of_the_line
    @io.write("\033[K")
  end

  # Reset the color
  def reset_color
    @io.write("\033[0m")
  end

  # Set the color
  # @param id_color [Integer] ID of the color (0 = black, 1 = red, 2 = green, 4 = blue, ...)
  # @param is_light [Boolean] if the color is lighten
  def set_color(id_color, is_light: false)
    if is_light
      @io.write("\033[1;3#{id_color & 7}m")
    else
      @io.write("\033[0;3#{id_color & 7}m")
    end
  end

  # Set the color with background
  # @param id_color [Integer] ID of the color (0 = black, 1 = red, 2 = green, 4 = blue, ...)
  # @param id_background [Integer] ID of the color (0 = black, 1 = red, 2 = green, 4 = blue, ...)
  # @param is_light [Boolean] if the color is lighten
  def set_color_with_background(id_color, id_background, is_light: false)
    if is_light
      @io.write("\033[4#{id_background & 7};1;3#{id_color & 7}m")
    else
      @io.write("\033[4#{id_background & 7};3#{id_color & 0x07}m")
    end
  end
end
