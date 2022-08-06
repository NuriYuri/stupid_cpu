require_relative 'terminal'

terminal = TerminalHelper.new

puts 'This will test the terminal helper'
print 'Press a key...'
STDIN.gets

terminal.title = "With a title it's better"
terminal.clear
terminal.set_cursor_position(0, 0)
terminal.puts 'We erased everything!'
print 'Press a key...'
STDIN.gets

terminal.clear
terminal.hide_cursor
61.times do |i|
  terminal.set_cursor_position(0, 1)
  terminal.reset_color
  terminal.write("[#{"=" * (i % 10)}#{" " * (10 - i % 10)}]")
  terminal.set_cursor_position(0, 4)
  terminal.move_cursor_forward(80 - 12)
  terminal.set_color_with_background(7, 2)
  terminal.write("[#{"=" * (i % 10)}#{" " * (10 - i % 10)}]")
  sleep(0.05)
end

color_codes = [1, 3, 2, 6, 4, 5]
(color_codes.size * 4).times do |i|
  terminal.set_color_with_background(0, color_codes[i % color_codes.size])
  terminal.clear
  sleep(0.25)
end

terminal.reset_color
terminal.clear
terminal.show_cursor
terminal.set_cursor_position(0, 0)
