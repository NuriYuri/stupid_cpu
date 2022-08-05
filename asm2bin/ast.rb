# frozen_string_literal: true

module ASM2Bin
  # Class responsive of building the AST
  # @note This AST is not an example, it's an AST of assembly instruction so it doesn't have to be as complex as regular ast
  class AST
    # List of token types that are values
    VALUE_TOKENS = %i[octal_literal hex_literal number_literal binary_literal identifier]
    # List of valid value that can be stored into the heap
    HEAP_VALUES = %i[octal_literal hex_literal number_literal binary_literal string symbol]
    # All the allowed patterns
    ALLOWED_PATTERNS = [
      # 1 value
      [
        %i[register],
        *VALUE_TOKENS.map { |v| [v] },
        %i[lbracket register rbracket],
        *VALUE_TOKENS.map { |v| [:lbracket, v, :rbracket] }
      ],
      # 2 values
      [
        *VALUE_TOKENS.map { |v| [:register, :comma, v] },
        %i[register comma register],
        %i[lbracket register rbracket comma register],
        %i[register comma lbracket register rbracket],
        *VALUE_TOKENS.map { |v| VALUE_TOKENS.map { |w| [:lbracket, v, :rbracket, :comma, w] } }.flatten(1),
        *VALUE_TOKENS.map { |v| [:lbracket, v, :rbracket, :comma, :register] },
        *VALUE_TOKENS.map { |v| [:register, :comma, :lbracket, v, :rbracket] }
      ]
    ]
    # Map giving the number of operand for each instructions
    INSTRUCTION_OPERAND_COUNT = {
      mov: 2, or: 2, and: 2, xor: 2, add: 2, sub: 2, mul: 2, shr: 2, shl: 2, ror: 2, rol: 2, test: 2, cmp: 2,
      jc: 1, jnc: 1, jh: 1, jnh: 1, jl: 1, jnl: 1, jz: 1, jnz: 1, inv: 1, inc: 1, dec: 1,
      poll: 1, sync: 1, lock: 1, unlock: 1,
      jmp: 1, nop: 0, dmaCopy: 0
    }

    # Get the program from the AST
    # @param tokens [Array<Lexer::Token>]
    # @return [Program]
    def build(tokens)
      tokens_without_comment = remove_comments(tokens)
      token_grouped_by_lines = group_token_by_lines(tokens_without_comment)
      @program = Program.new
      token_grouped_by_lines.each do |line|
        process_ast_for_line(line)
      end
      return @program
    end

    private

    # Remove the comments from the token list
    # @param tokens [Array<Lexer::Token>]
    # @return [Array<Lexer::Token>]
    def remove_comments(tokens)
      return tokens.reject { |token| token.type == :comment || token.type == :multi_line_comment }
    end

    # Group tokens by lines
    # @param tokens [Array<Lexer::Token>]
    # @return [Array<Array<Lexer::Token>>]
    def group_token_by_lines(tokens)
      return tokens.group_by(&:line).values
    end

    # Process the AST for the line
    # @param tokens [Array<Lexer::Token>]
    def process_ast_for_line(tokens)
      case tokens[0].type
      when :identifier
        process_identifier_ast(tokens)
      when :keyword
        process_instruction_ast(tokens)
      else
        raise SyntaxError, "unexpected #{tokens[0]} on line #{tokens[0].line}"
      end
    end

    # Process the identifier AST for the line
    # @param tokens [Array<Lexer::Token>]
    def process_identifier_ast(tokens)
      raise SyntaxError, "unexpected #{tokens[0]} on line #{tokens[0].line}" if tokens.size <= 1
      raise SyntaxError, "unexpected #{tokens[1]} on line #{tokens[1].line}" if tokens[1].type != :label_spec

      label = tokens[0].token
      raise SyntaxError, "duplicated label `#{label}` on line #{tokens[1].line}" if @program.labels.key?(label) || @program.symbols.key?(label)

      case tokens.size
      when 2
        @program.labels[label] = @program.instructions.size
      when 3
        raise SyntaxError, "unexpected #{tokens[2]} on line #{tokens[2].line}" unless HEAP_VALUES.include?(tokens[2].type)

        @program.symbols[label] = token_to_value(tokens[2])
      else
        raise SyntaxError, "unexpected #{tokens[3]} on line #{tokens[3].line}"
      end
    end

    # Process the instruction AST for the line
    # @param tokens [Array<Lexer::Token>]
    def process_instruction_ast(tokens)
      instruction, *rest = tokens
      pattern = rest.map(&:type)
      operand_count = INSTRUCTION_OPERAND_COUNT[instruction.token]
      case operand_count
      when 0
        process_instruction_ast0(tokens)
      when 1
        process_instruction_ast1(tokens, pattern)
      when 2
        process_instruction_ast2(tokens, pattern)
      else
        raise SyntaxError, "unexpected #{instruction} on line #{instruction.line}"
      end
    end

    # Process the instruction ast for an instruction with 0 operands
    # @param tokens [Array<Lexer::Token>]
    def process_instruction_ast0(tokens)
      raise SyntaxError, "unexpected #{tokens[1]} on line #{tokens[1].line}" if tokens.size > 1

      @program.instructions << Instruction.new(tokens)
    end

    # Process the instruction ast for an instruction with 1 operands
    # @param tokens [Array<Lexer::Token>]
    # @param pattern [Array<Symbol>]
    def process_instruction_ast1(tokens, pattern)
      allowed_patterns = ALLOWED_PATTERNS[0]
      return @program.instructions << Instruction::WithValue.new(tokens) if allowed_patterns.include?(pattern)

      raise_syntax_error_for_invalid_instruction(tokens, pattern, allowed_patterns)
    end

    # Process the instruction ast for an instruction with 2 operands
    # @param tokens [Array<Lexer::Token>]
    # @param pattern [Array<Symbol>]
    def process_instruction_ast2(tokens, pattern)
      allowed_patterns = ALLOWED_PATTERNS[1]
      return @program.instructions << Instruction::WithValues.new(tokens) if allowed_patterns.include?(pattern)

      raise_syntax_error_for_invalid_instruction(tokens, pattern, allowed_patterns)
    end

    # Process the instruction ast for an instruction with 2 operands
    # @param tokens [Array<Lexer::Token>]
    # @param pattern [Array<Symbol>]
    # @param allowed_patterns [Array<Array<Symbol>>]
    def raise_syntax_error_for_invalid_instruction(tokens, pattern, allowed_patterns)
      1.upto(pattern.size).each do |size|
        sub_pattern = pattern[range = 0...size]
        next if allowed_patterns.any? { |allowed_pattern| allowed_pattern[range] == sub_pattern }

        raise SyntaxError, "unexpected #{tokens[size]} on line #{tokens[size].line}; signature = #{pattern.join(', ')}"
      end

      raise SyntaxError, "unexpected #{tokens[pattern.size + 1]} on line #{tokens[pattern.size + 1].line}; signature = #{pattern.join(', ')}"
    end

    # Convert the token to a value
    # @param token [Lexer::Token]
    # @return [Integer, String]
    def token_to_value(token)
      case token.type
      when :octal_literal
        return token.token.to_i(8)
      when :hex_literal
        return token.token.to_i(16)
      when :binary_literal
        return token.token.to_i(2)
      when :number_literal
        return token.token.to_f if token.token.include?('e') || token.token.include?('.')

        return token.token.to_i
      when :string, :symbol
        return token.token[1...-1]
      else
        return token.token
      end
    end

    # Class describing a program
    class Program
      # All the labels pointing to an instructions
      # @return [Hash{ Symbol => Integer }]
      attr_reader :labels

      # All the symbols pointing to data in the memory
      # @return [Hash{ Symbol => String, Integer }]
      attr_reader :symbols

      # All the instructions of this program
      # @return [Array<Instruction>]
      attr_reader :instructions

      # Create a new program
      def initialize
        @labels = {}
        @symbols = {}
        @instructions = []
      end
    end

    # Class describing an Instruction
    class Instruction
      # All the instruction low bits
      LOW_BITS = {
        mov: 0b0000,
        or: 0b0001,
        and: 0b0010,
        xor: 0b0011,
        add: 0b0100,
        sub: 0b0101,
        mul: 0b0110,
        shr: 0b0111,
        shl: 0b1000,
        ror: 0b1001,
        rol: 0b1010,
        test: 0b1011,
        cmp: 0b1100,
        jc: 0b0000,
        jnc: 0b0001,
        jh: 0b0010,
        jnh: 0b0011,
        jl: 0b0100,
        jnl: 0b0101,
        jz: 0b0110,
        jnz: 0b0111,
        inv: 0b1000,
        inc: 0b1001,
        dec: 0b1010,
        poll: 0b1011,
        sync: 0b1100,
        lock: 0b1101,
        unlock: 0b1110,
        jmp: 0b1111,
        nop: 0b0000,
        dmaCopy: 0b0001
      }
      # All the register values
      REGISTERS = {
        r0: 0, r1: 1, r2: 2, r3: 3, r4: 4, r5: 5, r6: 6, r7: 7, pc: 0xC, st: 0xD, hp: 0xE,
        copyDataDmaDest: 0xF, currentDmaId: 8, copyDataSize: 9, copyDataSrcAddr: 0xA, copyDataDestAddr: 0xE
      }
      # Empty array (for performance)
      EMPTY_ARRAY = []

      # Get the instruction type
      # @return [Symbol]
      attr_reader :type

      # Get the high bits of the instruction
      # @return [Integer]
      def high
        0b001_00000
      end

      # Get the low bits of the instruction
      # @return [Integer]
      def low
        return LOW_BITS[@type] || 0
      end

      # Get the rest of the instruction data
      # @return [Integer]
      def rest
        return 0
      end

      # Get the extra data of the instruction
      # @return [Array<Integer>]
      def extra
        return EMPTY_ARRAY
      end

      # Get the instruction size (in 16bit words)
      def size
        return 1
      end

      # Create a new instruction
      # @param tokens [Array<Lexer::Token>]
      def initialize(tokens)
        @type = tokens.first.token
      end

      private

      # Convert the token to a value
      # @param token [Lexer::Token]
      # @return [Integer, String]
      def token_to_value(token)
        case token.type
        when :octal_literal
          return token.token.to_i(8) & 0xFFFF
        when :hex_literal
          return token.token.to_i(16) & 0xFFFF
        when :binary_literal
          return token.token.to_i(2) & 0xFFFF
        when :number_literal
          return token.token.to_f.to_i & 0xFFFF if token.token.include?('e') || token.token.include?('.')

          return token.token.to_i & 0xFFFF
        when :register
          return REGISTERS[token.token] || 0
        when :identifier
          return token.token
        else
          return 0
        end
      end

      class WithValue < Instruction
        # Get the instruction left value
        # @return [Integer, String]
        attr_reader :left

        # Tell if the left value is a pointer
        # @return [Boolean]
        attr_reader :is_left_pointer

        # Get the high bits of the instruction
        # @return [Integer]
        def high
          if @is_left_register
            return @is_left_pointer ? 0b110_10000 : 0b010_10000
          else
            return @is_left_pointer ? 0b100_10000 : 0b000_10000
          end
        end

        # Get the rest of the instruction data
        # @return [Integer]
        def rest
          return @is_left_register ? @left : 0
        end

        # Get the extra data of the instruction
        # @return [Array<Integer>]
        def extra
          return @is_left_register ? EMPTY_ARRAY : [@left]
        end

        # Get the instruction size (in 16bit words)
        def size
          return @is_left_register ? 1 : 2
        end

        # Create a new instruction
        # @param tokens [Array<Lexer::Token>]
        def initialize(tokens)
          super(tokens)
          if tokens[1].type == :lbracket
            @left = token_to_value(tokens[2])
            @is_left_register = tokens[2].type == :register
            @is_left_pointer = true
          else
            @left = token_to_value(tokens[1])
            @is_left_register = tokens[1].type == :register
            @is_left_pointer = false
          end
        end
      end

      class WithValues < WithValue
        # All the high bits mappings for 2 operand values
        HIGH_MAPPING = {
          'reg, val' => 0b010_00000,
          'reg, reg' => 0b011_00000,
          '[reg], reg' => 0b111_00000,
          'reg, [reg]' => 0b000_00000,
          '[val], val' => 0b100_00000,
          '[val], reg' => 0b101_00000,
          'reg, [val]' => 0b110_00000
        }
        # All the operand type mapping
        OPERAND_MAPPING = {
          true => {
            false => '[val]',
            true => '[reg]'
          },
          false => {
            false => 'val',
            true => 'reg'
          }
        }
        # Get the instruction right value
        # @return [Integer, String]
        attr_reader :right

        # Tell if the right value is a pointer
        # @return [Boolean]
        attr_reader :is_right_pointer

        # Get the high bits of the instruction
        # @return [Integer]
        def high
          left = OPERAND_MAPPING[@is_left_pointer][@is_left_register]
          right = OPERAND_MAPPING[@is_right_pointer][@is_right_register]
          return HIGH_MAPPING["#{left}, #{right}"] || 0
        end

        # Get the rest of the instruction data
        # @return [Integer]
        def rest
          if @is_left_register
            return @is_right_register ? @right | (@left << 4) : @left
          else
            return @is_right_register ? @right : 0
          end
        end

        # Get the extra data of the instruction
        # @return [Array<Integer>]
        def extra
          if @is_left_register
            return @is_right_register ? EMPTY_ARRAY : [@right]
          else
            return @is_right_register ? [@left] : [@left, @right]
          end
        end

        # Get the instruction size (in 16bit words)
        def size
          if @is_left_register
            return @is_right_register ? 1 : 2
          else
            return @is_right_register ? 2 : 3
          end
        end

        # Create a new instruction
        # @param tokens [Array<Lexer::Token>]
        def initialize(tokens)
          super(tokens)

          base_index = tokens.find_index { |token| token.type == :comma } + 1
          if tokens[base_index].type == :lbracket
            @right = token_to_value(tokens[base_index + 1])
            @is_right_register = tokens[base_index + 1].type == :register
            @is_right_pointer = true
          else
            @right = token_to_value(tokens[base_index])
            @is_right_register = tokens[base_index].type == :register
            @is_right_pointer = false
          end
        end
      end
    end
  end
end
