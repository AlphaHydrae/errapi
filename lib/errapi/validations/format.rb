module Errapi::Validations
  class Format

    def initialize options = {}
      @should_match = options.key? :with
      @format = check_format! options[:with] || options[:without]
      raise ArgumentError, "Either :with or :without must be given (but not both)." unless options.key?(:with) ^ options.key?(:without)
    end

    def validate value, context, options = {}
      r = regexp options[:source]
      if r.match(value.to_s) != @should_match
        context.add_error reason: :invalid_format, check_value: @format
      end
    end

    private

    def regexp source

      r = if @format.respond_to? :call
        @format.call source
      elsif @format.respond_to? :to_sym
        source.send @format
      else
        @format
      end

      raise ArgumentError, "A regular expression must be returned from the given proc or lambda, or from calling the method corresponding to the given symbol, but a #{@format.class.name} was returned." if FORMAT_METHOD_CHECKS.none?{ |m| @format.respond_to? m }
      # TODO: add warning if regexp contains multiline anchors

      r
    end

    def check_format! format
      if format.nil?
        nil
      elsif !format.respond_to?(:call) && !format.kind_of?(Regexp)
        raise ArgumentError, "The :with (or :without) option must be a regular expression, a proc, a lambda or a symbol, but a #{format.class.name} was given."
        format
      end
    end

    private

    FORMAT_METHOD_CHECKS = %i(include? call to_sym).freeze
  end
end
