module Errapi::Validations
  class Numericality < Base
    class Factory < ValidationFactory
      build Numericality
    end

    CHECKS = { greater_than: :>, greater_than_or_equal_to: :>=,
               equal_to: :==, less_than: :<, less_than_or_equal_to: :<=,
               odd: :odd?, even: :even?, other_than: :!= }

    OPTIONS = CHECKS.keys + %i(only_integer)
    NUMERIC_OPTIONS = CHECKS.keys - %i(odd even)

    REASONS = { greater_than: :not_greater_than, greater_than_or_equal_to: :not_greater_than_or_equal_to,
                equal_to: :not_equal_to, less_than: :not_less_than, less_than_or_equal_to: :not_less_than_or_equal_to,
                odd: :not_odd, even: :not_even, other_than: :not_other_than, only_integer: :not_an_integer }

    def initialize options = {}

      keys = options.keys.select{ |k| OPTIONS.include? k }
      if keys.empty?
        raise ArgumentError, "At least one option of #{OPTIONS.collect{ |o| ":#{o}" }.join(', ')} must be supplied."
      end

      NUMERIC_OPTIONS.each do |key|
        value = options[key]
        unless !options.key?(key) || value.kind_of?(Numeric) || callable_option_value?(value)
          raise callable_option_type_error ":#{key}", "a numeric value", value
        end
      end

      @constraints = options
    end

    def validate value, context, options = {}
      return unless value.kind_of? Numeric

      keys = CHECKS.keys.select{ |k| @constraints.key? k }

      actual_constraints = keys.inject({}) do |memo,key|
        memo[key] = actual_check_value key, @constraints[key], options
        memo
      end

      CHECKS.each_pair do |key,check|
        next unless check_value = actual_constraints[key]

        if NUMERIC_OPTIONS.include? key
          next if value.send check, check_value
        else
          next if value.send check
        end

        context.add_error reason: REASONS[key], check_value: check_value, checked_value: value, constraints: actual_constraints
      end
    end

    private

    def actual_check_value key, value, options
      actual_value = actual_option_value value, options
      if NUMERIC_OPTIONS.include?(key) && !actual_value.kind_of?(Numeric)
        raise callable_option_value_error ":#{key}", "a numeric value", value
      end
      actual_value
    end
  end
end
