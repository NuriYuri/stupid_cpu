require_relative '../lexer'
require_relative '../ast'
require 'yaml'

data = File.read('ast_input_all_instructions.asm')
tokens = ASM2Bin::Lexer.new.compute_token(data).tokens
program = ASM2Bin::AST.new.build(tokens)
File.write('ast_output_all_instructions.yml', YAML.dump(program))
