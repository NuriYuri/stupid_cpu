# frozen_string_literal: true

require_relative 'lexer'

describe(ASM2Bin::Lexer) do
  it('lexes assembly properly') do
    lexer = ASM2Bin::Lexer.new
    tokens = lexer.compute_token(File.read(File.join(__dir__, 'test/lexer_input.asm'))).tokens
    structured_tokens = tokens.group_by(&:line).values.map { |line| line.join(' ') }.join("\n")
    expect(structured_tokens).to eq(File.read(File.join(__dir__, 'test/lexer_output.txt')))
  end
end
