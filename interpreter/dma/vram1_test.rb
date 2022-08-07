require_relative '../helpers/terminal'
require_relative 'dma'
require_relative 'vram1'

def wait
  STDOUT.write("\x07")
  STDIN.gets
end
terminal = TerminalHelper.new
terminal.title = 'VRAM1 test'
vram = Interpreter::VRAM1.new(terminal)
vram.write(0xFFFF << 1, 1.chr) # Going to video mode clears the screen
vram.write(0xFFFF << 1, 0.chr) # Should redraw the whole data but nothing is here to be drawn

# Display hello world in top of the terminal
vram.write(0, 'Hello World!')
wait
# Change the color of the text
#                          H   e   l   l   o   sp  W   o   r   l   d   !
vram.write(0x0F00 << 1, "\x70\x07\x02\x72\x07\x07\x06\x03\x21\x30\x60\x00\x70\x20")
wait

# Set color attribute to be light blue, move cursor out of screen & display !dlroW olleH
vram.write(0xFFFC << 1, [0b000_1_100].pack('S>'))
vram.write(0xFFFD << 1, "\xFF\xFF\xFF\xFF")
vram.write(0, '!dlroW olleH')
wait

# Test that line stop after any ASCII control char
vram.write(0, "Hello\nWorld!")
wait

# Test that we can only write 80 char per line
vram.write(0, '80!!'.rjust(82))
wait

# Test all the colors
vram.write(0xFFFC << 1, [0b000_0_001].pack('S>'))
vram.write(0, "red\x00") # Clear the line
vram.write(0xFFFC << 1, [0b000_0_011].pack('S>'))
vram.write(320, 'yellow')

vram.write(0xFFFC << 1, [0b000_0_010].pack('S>'))
vram.write(640, 'green')
vram.write(0xFFFC << 1, [0b000_0_110].pack('S>'))
vram.write(960, 'cyan')
vram.write(0xFFFC << 1, [0b000_0_100].pack('S>'))
vram.write(1280, 'blue')
vram.write(0xFFFC << 1, [0b000_0_101].pack('S>'))
vram.write(1600, 'purple')
vram.write(0xFFFC << 1, [0b000_0_111].pack('S>'))
vram.write(1920, 'light gray')

vram.write(0xFFFC << 1, [0b000_1_001].pack('S>'))
vram.write(2240, 'light red')
vram.write(0xFFFC << 1, [0b000_1_011].pack('S>'))
vram.write(2560, 'light yellow')
vram.write(0xFFFC << 1, [0b000_1_010].pack('S>'))
vram.write(2880, 'light green')
vram.write(0xFFFC << 1, [0b000_1_110].pack('S>'))
vram.write(3200, 'light cyan')
vram.write(0xFFFC << 1, [0b000_1_100].pack('S>'))
vram.write(3520, 'light blue')
vram.write(0xFFFC << 1, [0b000_1_101].pack('S>'))
vram.write(3840, 'light purple')
vram.write(0xFFFC << 1, [0b000_1_111].pack('S>'))
vram.write(4160, 'white')

vram.write(0xFFFC << 1, [0b001_0_000].pack('S>'))
vram.write(4480, 'red')
vram.write(0xFFFC << 1, [0b011_0_000].pack('S>'))
vram.write(4800, 'yellow')
vram.write(0xFFFC << 1, [0b010_0_000].pack('S>'))
vram.write(5120, 'green')
vram.write(0xFFFC << 1, [0b110_0_000].pack('S>'))
vram.write(5440, 'cyan')
vram.write(0xFFFC << 1, [0b100_0_000].pack('S>'))
vram.write(5760, 'blue')
vram.write(0xFFFC << 1, [0b101_0_000].pack('S>'))
vram.write(6080, 'purple')
vram.write(0xFFFC << 1, [0b111_0_000].pack('S>'))
vram.write(6400, 'light gray')
wait

# Test writing the full VRAM
srand(100)
text_mem = 24.times.map { 320.times.map { rand(32..126) } }.flatten.pack('C*')
attribute_memory = 24.times.map { 80.times.map { rand(0..0b111_1_111) } }.flatten.pack('C*')
padding = "\x00" * 121_472
vram.write(0, text_mem << attribute_memory << padding)
wait

# Test framerate
t = Time.new
sleep(0.01)
vram.write(0xFFFC << 1, [0b000_1_100].pack('S>'))
vram.write(0xFFFD << 1, "\xFF\xFF\xFF\xFF")
32.times do
  dt = Time.new - t
  fps = (1.0 / dt).round(2)
  text_mem = 24.times.map do |i|
    next (i.odd? ? dt.to_s : "#{fps} FPS").ljust(320, ' ')
  end.join
  t = Time.new
  vram.write(0, text_mem)
end
wait

# Test framerate low update
t = Time.new
sleep(0.01)
32.times do
  dt = Time.new - t
  fps = (1.0 / dt).round(2)
  text_mem = 24.times.map do |i|
    next (i.odd? ? dt.to_s : "#{fps} FPS").ljust(320, "\x00")
  end.join
  t = Time.new
  vram.write(0, text_mem)
end
wait

# Test framerate with only few char updated
t = Time.new
text_mem = 24.times.map { 320.times.map { ' ' } }.flatten.join
vram.write(0, text_mem)
sleep(0.01)
320.times do |i|
  dt = Time.new - t
  fps = (1.0 / dt).round(2)
  t = Time.new
  vram.write(1, "#{fps} FPS".rjust(10, ' '))
  j = i % 80
  vram.write(j == 0 ? 320 + 80 : 319 + j, ' ')
  vram.write(320 + j, '*')
  sleep(0.01)
end
wait

terminal.reset_color
terminal.clear
