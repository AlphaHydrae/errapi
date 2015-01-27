module Errapi::Validations
  class Format < Base
    class Factory < ValidationFactory
      build Format
    end

    def initialize options = {}
      unless key = exactly_one_option?(OPTIONS, options)
        raise ArgumentError, "Either :with or :without must be supplied (but not both)."
      end

      @format = options[key]
      @should_match = key == :with

      unless @format.kind_of?(Regexp) or callable_option_value?(@format)
        raise callable_option_type_error ":with (or :without)", "a regular expression", @format
      end
    end

    def validate value, context, options = {}

      regexp = actual_option_value @format, options
      unless regexp.kind_of? Regexp
        raise callable_option_value_error ":with (or :without)", "a regular expression", regexp
      end

      if !regexp.match(value.to_s) == @should_match
        context.add_error reason: :invalid_format, check_value: regexp
      end
    end

    private

    OPTIONS = %i(with without)
  end
end
