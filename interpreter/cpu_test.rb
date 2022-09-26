require_relative 'cpu'

cpu = Interpreter::CPU.new('../asm2bin/examples/hello_world_out/hello_world')
p cpu.instance_variable_get(:@pram).read(0, 24)
p cpu.instance_variable_get(:@north_bridge)[64].read(0, 24)
p cpu.instance_variable_get(:@registers).read(0, 64)

decoder = cpu.decoder
registers = cpu.instance_variable_get(:@registers)
9.times do
  decoder.decode
  inst =  decoder.instruction
  left = decoder.is_left_pointer ? "[#{decoder.left}]" : decoder.left
  right = decoder.is_right_pointer ? "[#{decoder.right}]" : decoder.right
  puts "#{inst} #{left}, #{right}"
  registers.write_register_int(:pc, registers.register_uint(:pc) + decoder.instruction_size)
end
