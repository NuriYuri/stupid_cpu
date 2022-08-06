require_relative 'lexer'
require_relative 'ast'
require_relative 'sem'
require 'yaml'

describe(ASM2Bin::Sem) do
  it('properly generate the program based on ast program') do
    tokens = ASM2Bin::Lexer.new.compute_token(File.read(File.join(__dir__, 'test/sem_input.asm'))).tokens
    program = ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens))
    expect(YAML.dump(program)).to eq(File.read(File.join(__dir__, 'test/sem_output.yml')))
  end

  it('properly handle various kind of integers') do
    tokens = ASM2Bin::Lexer.new.compute_token(File.read(File.join(__dir__, 'test/sem_integers_input.asm'))).tokens
    program = ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens))
    expect(YAML.dump(program)).to eq(File.read(File.join(__dir__, 'test/sem_integers_output.yml')))
  end

  it('Throws an error if the integer is too big') do
    tokens = ASM2Bin::Lexer.new.compute_token('data: 0x1_FFFF_FFFF_FFFF_FFFF').tokens
    expect { ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens)) }.to raise_error(RuntimeError, 'Integer 36893488147419103231 is too big')
    tokens = ASM2Bin::Lexer.new.compute_token('data: -9223372036854775809').tokens
    expect { ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens)) }.to raise_error(RuntimeError, 'Integer -9223372036854775809 is too big')
  end
end
