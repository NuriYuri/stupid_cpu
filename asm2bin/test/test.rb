require_relative '../lexer'
require_relative '../ast'
require_relative '../sem'
require 'yaml'

data = File.read('sem_integers_input.asm')
tokens = ASM2Bin::Lexer.new.compute_token(data).tokens
program = ASM2Bin::AST.new.build(tokens)
semantic_program = Dir.chdir('../..') do
  break ASM2Bin::Sem.new.parse(program)
end
File.write('sem_integers_output.yml', YAML.dump(semantic_program))
