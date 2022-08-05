# frozen_string_literal: true

# Module holding the language 2 classes
module ASM2Bin
  # Class responsive of building tokens out of assembly file
  class Lexer
    # Get all the tokens
    # @return [Array<Token>]
    attr_reader :tokens

    # Create a new tokenizer
    def initialize
      @current_token = ''.dup
      @tokens = []
      @line = 0
      @char_index = 0
      @token_position = 1
    end

    # Lex a lexable input
    # @param input [IO, String]
    # @return [self]
    def compute_token(input)
      @current_line = 0
      input.each_line do |line|
        @current_line += 1
        parse_line(line)
      end
      # Ensure that last line produce its last token in case it doesn't end with \n
      parse_token(@current_token, '')
      return self
    end

    private

    # Extract all the tokens in the current line
    # @param line [String]
    def parse_line(line)
      @line += 1
      line.each_char.with_index do |char, position|
        @char_index = position
        parse_token(@current_token, char)
      end
    end

    # Add a new token to the stack
    # @param type [Symbol]
    def add_token(type)
      @tokens << Token.new(@current_token, type, @line, @token_position)
      @current_token = ''.dup
    end

    # Push a char to the current token (avoiding whitespace)
    # @param char [String]
    def push(char)
      @current_token << char unless char =~ /[[:space:]]/
      define_token_position
    end

    # Push a char to the current token
    # @param char [String]
    def push!(char)
      @current_token << char
      define_token_position
    end

    # Parse the current char to an actual token
    # @param current_token [String]
    # @param char [String]
    def parse_token(current_token, char)
      case current_token
      when '['
        add_token(:lbracket)
        push(char)
      when ']'
        add_token(:rbracket)
        push(char)
      when ','
        add_token(:comma)
        push(char)
      when ':'
        add_token(:label_spec)
        push(char)
      when /^"/
        if current_token[-1] != '\\' && char == '"'
          push!(char)
          add_token(:string)
          return
        end
        push!(char)
      when /^'/
        if current_token[-1] != '\\' && char == "'"
          push!(char)
          add_token(:symbol)
          return
        end
        push!(char)
      when /^0[0-9]/
        if char =~ /[0-9_]/
          push(char)
          return
        end
        add_token(:octal_literal)
        push(char)
      when /^0x/
        if char =~ /[0-9a-f_]/i
          push(char)
          return
        end
        add_token(:hex_literal)
        push(char)
      when /^0b/
        if char =~ /[01_]/i
          push(char)
          return
        end
        add_token(:binary_literal)
        push(char)
      when /^[\-+0-9]/
        case char
        when 'x', 'b'
          add_token(:number_literal) if current_token.size != 1
        when '.'
          add_token(:number_literal) if current_token.include?('.')
        when 'e'
          add_token(:number_literal) if current_token.include?('e')
        when '+', '-'
          add_token(:number_literal) if current_token[-1] != 'e'
        else
          add_token(:number_literal) unless char =~ /[0-9_]/
        end
        push(char)
      when 'r0', 'r1', 'r2', 'r3', 'r4', 'r5', 'r6', 'r7', 'st', 'pc', 'hp', 'copyDataDmaDest', 'copyDataDestAddr', 'currentDmaId',
           'copyDataSize', 'copyDataSrcAddr'
        return push(char) if char =~ /[[:alnum:]_]/

        add_token(:register)
        push(char)
      when 'mov', 'or', 'and', 'xor', 'add', 'sub', 'mul', 'shr', 'shl', 'ror', 'rol', 'test', 'cmp', 'jc', 'jnc', 'jh', 'jnh', 'jl', 'jnl', 'jz',
           'jnz', 'inv', 'inc', 'dec', 'poll', 'sync', 'lock', 'unlock', 'jmp', 'nop', 'dmaCopy'
        return push(char) if char =~ /[[:alnum:]_]/

        add_token(:keyword)
        push(char)
      when /^[[:lower:]]/
        return push(char) if char =~ /[[:alnum:]_]/

        add_token(:identifier)
        push(char)
      when /^#/, /^\/\//, /^;/
        return add_token(:comment) if char == "\n" || char == ''

        push!(char)
      when /^\/\*/
        if char == '/' && current_token[-1] == '*' || char == ''
          push(char)
          original_line = @line
          @line -= current_token.count("\n")
          add_token(:multi_line_comment)
          @line = original_line
          return
        end
        push!(char)
      when /^[#\/;]/
        push(char)
      else
        add_token(:unknown) unless current_token.empty?
        push(char)
      end
    end

    # Set the position of the current token
    def define_token_position
      @token_position = @char_index + 1 if @current_token.size == 1
    end

    # Class representing a token
    class Token
      # List of void tokens
      VOID_TOKENS = %i[lbracket rbracket comma label_spec]
      # @return [String, Symbol, nil]
      attr_reader :token

      # @return [Symbol]
      attr_reader :type

      # @return [Integer]
      attr_reader :line

      # @return [Integer]
      attr_reader :position

      # Create a new token
      def initialize(token, type, line, position)
        @token = VOID_TOKENS.include?(type) ? nil : token
        @token = @token.to_sym if type == :keyword || type == :register || type == :identifier
        @type = type
        @line = line
        @position = position
      end

      def to_s
        @token ? "<t:#{@type} @#{@line}:#{@position} #{@token}>" : "<t:#{@type} @#{@line}:#{@position}>"
      end
    end
  end
end
