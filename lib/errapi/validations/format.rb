module Errapi::Validations
  class Format < Base

    def initialize options = {}
      key = check_exactly_one_option!(OPTIONS, options){ "Either :with or :without must be supplied (but not both)." }
      @format = check_callable_option_value!(options[key], Regexp){ |format| "The :with (or :without) option must be a regular expression, a proc, a lambda or a symbol, but a #{format.class.name} was given." }
      @should_match = options.key? :with
    end

    def validate value, context, options = {}
      regexp = option_value!(@format, options[:source], Regexp){ |format| "A regular expression must be returned from the supplied call, but a #{format.class.name} was returned." }
      if !regexp.match(value.to_s) == @should_match
        context.add_error reason: :invalid_format, check_value: regexp
      end
    end

    private

    OPTIONS = %i(with without)
  end
end
