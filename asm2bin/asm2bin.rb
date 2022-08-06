require 'optparse'
require_relative 'lexer'
require_relative 'ast'
require_relative 'sem'
require_relative 'generator'

options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: asm2bin.rb [options] PROGRAM_FILENAME"

  parser.on("-CDIRECTORY", "--working-directory=DIRECTORY", "CD to the DIRECTORY while parsing the program data") do |v|
    options[:working_directory] = v
  end

  parser.on("-ODIRECTORY", "--output-directory=DIRECTORY", "CD to the DIRECTORY while writing the program output") do |v|
    options[:output_directory] = v
  end

  parser.on("-N", "--no-padding", "disable file padding") do |v|
    options[:no_padding] = true
  end
end.parse!

raise "Invalid argument count #{ARGV.size}" if ARGV.size != 1

if options[:working_directory]
  Dir.chdir(options[:working_directory]) do
    tokens = ASM2Bin::Lexer.new.compute_token(File.read(ARGV[0])).tokens
    $program = ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens))
  end
else
  tokens = ASM2Bin::Lexer.new.compute_token(File.read(ARGV[0])).tokens
  $program = ASM2Bin::Sem.new.parse(ASM2Bin::AST.new.build(tokens))
end

program_name = ARGV[0].sub(/.asm$/i, '')
generator = ASM2Bin::Generator.new(dont_pad: !!options[:no_padding])

if options[:output_directory] || options[:working_directory]
  Dir.chdir(options[:output_directory] || options[:working_directory]) do
    generator.generate($program, program_name)
  end
else
  generator.generate($program, program_name)
end
