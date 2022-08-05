# frozen_string_literal: true

require_relative 'lexer'
require_relative 'ast'
require 'yaml'

describe(ASM2Bin::AST) do
  it('Generate ast of basic program with 3 type of instructions & few constants/labels') do
    tokens = ASM2Bin::Lexer.new.compute_token(File.read(File.join(__dir__, 'test/ast_input_partial.asm'))).tokens
    ast = ASM2Bin::AST.new.build(tokens)
    expect(YAML.dump(ast)).to eq(File.read(File.join(__dir__, 'test/ast_output_partial.yml')))
  end

  it('Generate ast of every instruction with all possible operand kind') do
    tokens = ASM2Bin::Lexer.new.compute_token(File.read(File.join(__dir__, 'test/ast_input_all_instructions.asm'))).tokens
    ast = ASM2Bin::AST.new.build(tokens)
    expect(YAML.dump(ast)).to eq(File.read(File.join(__dir__, 'test/ast_output_all_instructions.yml')))
  end

  it('throws as SyntaxError when first token of the line is not expected') do
    tokens = ASM2Bin::Lexer.new.compute_token("0\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'unexpected <t:number_literal @1:1 0> on line 1')
  end

  it('throws as SyntaxError when label is not followed by anything') do
    tokens = ASM2Bin::Lexer.new.compute_token("label\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'unexpected <t:identifier @1:1 label> on line 1')
  end

  it('throws as SyntaxError when label is not followed by colon') do
    tokens = ASM2Bin::Lexer.new.compute_token("label mov\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'unexpected <t:keyword @1:7 mov> on line 1')
  end

  it('throws as SyntaxError when label is duplicated') do
    tokens = ASM2Bin::Lexer.new.compute_token("label:\nlabel:\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'duplicated label `label` on line 2')
  end

  it('throws as SyntaxError when constant is containing more than a single value') do
    tokens = ASM2Bin::Lexer.new.compute_token("label: 0 1\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'unexpected <t:number_literal @1:10 1> on line 1')
  end

  it('throws as SyntaxError when an instruction does not exist') do
    tokens = ASM2Bin::Lexer.new.compute_token("nop\n").tokens
    tokens[0].instance_variable_set(:@token, :unknown)
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'unexpected <t:keyword @1:1 unknown> on line 1')
  end

  it('throws as SyntaxError when an instruction with no operand has any') do
    tokens = ASM2Bin::Lexer.new.compute_token("nop 0\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(ScriptError, 'unexpected <t:number_literal @1:5 0> on line 1')
  end

  it('throws as SyntaxError when an instruction with one operand has more than one') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp 0 1\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(
      ScriptError,
      'unexpected <t:number_literal @1:7 1> on line 1; signature = number_literal, number_literal'
    )
  end

  it('throws as SyntaxError when an instruction with one operand has an invalid operand') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp 'test'\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(
      ScriptError,
      'unexpected <t:symbol @1:5 \'test\'> on line 1; signature = symbol'
    )
  end

  it('throws as SyntaxError when an instruction with two operand has more than two') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp r0 1 2\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(
      ScriptError,
      'unexpected <t:number_literal @1:8 1> on line 1; signature = register, number_literal, number_literal'
    )
  end

  it('throws as SyntaxError when an instruction with two operand has an invalid operand') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp r0 'test'\n").tokens
    expect { ASM2Bin::AST.new.build(tokens) }.to raise_exception(
      ScriptError,
      'unexpected <t:symbol @1:8 \'test\'> on line 1; signature = register, symbol'
    )
  end
end
