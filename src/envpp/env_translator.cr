module Envpp
  class TranslationError < Exception; end

  class EnvTable
    def initialize(source : ENV.class | Hash(String, String))
      @source = source
    end

    def has_key?(name : String)
      @source.has_key?(name)
    end

    def fetch(name : String, default : String?)
      @source.fetch(name, default)
    end
  end

  class EnvTranslator
    private struct Variable
      property name : String::Builder
      property default : String::Builder
      property delimeter : Char? = nil

      def initialize
        @name = String::Builder.new
        @default = String::Builder.new
      end

      def reset!
        @name = String::Builder.new
        @default = String::Builder.new
        @delimeter = nil
      end
    end

    def initialize(@env_table : EnvTable)
      @symbol_table = {} of String => String
      @line_buffer = String::Builder.new
      @line_number = 0
      @character_number = 0
      @variable = Variable.new
    end

    def translate_line(line : String)
      @line_number =+ 1
      @line_buffer = String::Builder.new unless @line_buffer.empty?
      state = :echoing_text

      line.each_char_with_index do |character, i|
        @character_number = i + 1

        case state
        when :echoing_text
          state = handle_echoing_text!(character)
        when :escaping_text
          state = handle_escaping_text!(character)
        when :parsing_variable
          state = handle_parsing_variable!(character)
        when :parsing_default
           state = handle_parsing_default!(character)
        else
          raise "Invalid translation state: #{state}"
        end
      end

      if state == :parsing_variable || state == :parsing_default
        raise TranslationError.new("Invalid variable at #{@line_number}:#{@character_number}")
      end

      @line_buffer.to_s
    end

    private def handle_echoing_text!(character : Char) : Symbol
      case character
      when '\\'
        return :escaping_text
      when '$'
        return :parsing_variable
      else
        @line_buffer << character.to_s
        return :echoing_text
      end
    end

    private def handle_escaping_text!(character : Char) : Symbol
      @line_buffer << "\\" if character != '$'

      @line_buffer << character.to_s
      return :echoing_text
    end

    private def handle_parsing_variable!(character : Char) : Symbol
      if @variable.name.empty?
        if character == '{'
          @variable.delimeter = '}'
          return :parsing_variable
        elsif character == '('
          @variable.delimeter = ')'
          return :parsing_variable
        end


        unless /\w/i.matches?(character.to_s)
          raise TranslationError.new("Invalid variable at #{@line_number}:#{@character_number}")
        end
      end

      case character.to_s
      when ":"
        return :parsing_default
      when /(\}|\))/
        raise "Invalid variable at #{@line_number}:#{@character_number}" unless character == @variable.delimeter

        @line_buffer << fetch_variable_value(@variable.name.to_s, @variable.default.to_s)
        @variable.reset!
        return :echoing_text
      when /[A-Z0-9_]/i
        @variable.name << character.to_s
        return :parsing_variable
      else
        raise TranslationError.new("Invalid character '#{character}' in variable at #{@line_number}:#{@character_number}")
      end
    end

    private def handle_parsing_default!(character : Char) : Symbol
      if character == @variable.delimeter
        @line_buffer << fetch_variable_value(@variable.name.to_s, @variable.default.to_s)
        @variable.reset!
        return :echoing_text
      else
        @variable.default << character
        return :parsing_default
      end
    end

    private def fetch_variable_value(name : String, default : String? = nil)
      raise "Variable name can't be nil" if name.nil?

      return @symbol_table[name] if @symbol_table.has_key?(name)

      value = @env_table.fetch(name, default.empty? ? nil : default)
      raise "Variable #{name} not set!" if value.nil?

      @symbol_table[name] = value
    end
  end
end
