# frozen_string_literal: true

require_relative 'lexer'
require_relative 'ast'

describe(ASM2Bin::AST::Instruction) do
  it('gives the right data for 0 operand instruction') do
    tokens = ASM2Bin::Lexer.new.compute_token("dmaCopy\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b001_00000)
    expect(instruction.low).to eq(0b000_00001)
    expect(instruction.size).to eq(1)
    expect(instruction.rest).to eq(0b0000_0000)
    expect(instruction.extra).to eq([])
    expect(instruction.type).to eq(:dmaCopy)
  end

  it('gives the right data for "instr reg"') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp r7\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b010_10000)
    expect(instruction.low).to eq(0b000_01111)
    expect(instruction.size).to eq(1)
    expect(instruction.rest).to eq(0b0000_0111)
    expect(instruction.extra).to eq([])
    expect(instruction.type).to eq(:jmp)
  end

  it('gives the right data for "instr val"') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp value\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b000_10000)
    expect(instruction.low).to eq(0b000_01111)
    expect(instruction.size).to eq(2)
    expect(instruction.rest).to eq(0b0000_0000)
    expect(instruction.extra).to eq([:value])
    expect(instruction.type).to eq(:jmp)
  end

  it('gives the right data for "instr [val]"') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp [ptr]\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b100_10000)
    expect(instruction.low).to eq(0b000_01111)
    expect(instruction.size).to eq(2)
    expect(instruction.rest).to eq(0b0000_0000)
    expect(instruction.extra).to eq([:ptr])
    expect(instruction.type).to eq(:jmp)
  end

  it('gives the right data for "instr [reg]"') do
    tokens = ASM2Bin::Lexer.new.compute_token("jmp [r7]\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b110_10000)
    expect(instruction.low).to eq(0b000_01111)
    expect(instruction.size).to eq(1)
    expect(instruction.rest).to eq(0b0000_0111)
    expect(instruction.extra).to eq([])
    expect(instruction.type).to eq(:jmp)
  end

  it('gives the right data for "instr reg, val"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp r7, value\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b010_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(2)
    expect(instruction.rest).to eq(0b0000_0111)
    expect(instruction.extra).to eq([:value])
    expect(instruction.type).to eq(:cmp)
  end

  it('gives the right data for "instr reg, reg"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp r7, r6\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b011_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(1)
    expect(instruction.rest).to eq(0b0111_0110)
    expect(instruction.extra).to eq([])
    expect(instruction.type).to eq(:cmp)
  end

  it('gives the right data for "instr [reg], reg"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp [r7], r6\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b111_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(1)
    expect(instruction.rest).to eq(0b0111_0110)
    expect(instruction.extra).to eq([])
    expect(instruction.type).to eq(:cmp)
  end

  it('gives the right data for "instr reg, [reg]"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp r7, [r6]\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b000_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(1)
    expect(instruction.rest).to eq(0b0111_0110)
    expect(instruction.extra).to eq([])
    expect(instruction.type).to eq(:cmp)
  end

  it('gives the right data for "instr [val], val"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp [ptr], value\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b100_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(3)
    expect(instruction.rest).to eq(0b0000_0000)
    expect(instruction.extra).to eq(%i[ptr value])
    expect(instruction.type).to eq(:cmp)
  end

  it('gives the right data for "instr [val], reg"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp [ptr], r6\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b101_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(2)
    expect(instruction.rest).to eq(0b0000_0110)
    expect(instruction.extra).to eq([:ptr])
    expect(instruction.type).to eq(:cmp)
  end

  it('gives the right data for "instr reg, [val]"') do
    tokens = ASM2Bin::Lexer.new.compute_token("cmp r6, [ptr]\n").tokens
    instruction = ASM2Bin::AST.new.build(tokens).instructions.first
    expect(instruction.high).to eq(0b110_00000)
    expect(instruction.low).to eq(0b000_01100)
    expect(instruction.size).to eq(2)
    expect(instruction.rest).to eq(0b0000_0110)
    expect(instruction.extra).to eq([:ptr])
    expect(instruction.type).to eq(:cmp)
  end
end
