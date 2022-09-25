require_relative 'cpu'

cpu = Interpreter::CPU.new('../asm2bin/examples/hello_world_out/hello_world')
p cpu.instance_variable_get(:@pram).read(0, 24)
p cpu.instance_variable_get(:@north_bridge)[64].read(0, 24)
p cpu.instance_variable_get(:@registers).read(0, 64)
