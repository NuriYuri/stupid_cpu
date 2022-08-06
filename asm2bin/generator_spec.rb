require_relative 'lexer'
require_relative 'ast'
require_relative 'sem'
require_relative 'generator'

describe(ASM2Bin::Generator) do
  it('generates the content properly') do
    tokens = ASM2Bin::Lexer.new.compute_token("data: 123\ntext: 'Hello world!'\nnop\nnop").tokens
    program = ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens))
    generator = ASM2Bin::Generator.new(dont_pad: true, output_to_memory: true)
    expect(generator.generate(program, 'test')).to eq({
      "test.pram.bin" => " \x00 \x00",
      "test.rom.0.bin" => "\x00{Hello world!"
    })
  end
end
