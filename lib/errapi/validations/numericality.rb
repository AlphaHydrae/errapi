module Errapi::Validations
  class Numericality < Base
    class Factory < ValidationFactory
      build Numericality
    end

    CHECKS = { greater_than: :>, greater_than_or_equal_to: :>=,
               equal_to: :==, less_than: :<, less_than_or_equal_to: :<=,
               odd: :odd?, even: :even?, other_than: :!= }

    NUMERIC_CHECKS = CHECKS.keys - %i(odd even)

    REASONS = { greater_than: :greater_than_exclusive, greater_than_or_equal_to: :greater_than_inclusive,
                equal_to: :not_equal_to, less_than: :less_than_exclusive, less_than_or_equal_to: :less_than_inclusive,
                odd: :not_odd, even: :not_even, other_than: :not_other_than, only_integer: :not_an_integer }

    def initialize options = {}

      NUMERIC_CHECKS.each_pair do |key,value|
        unless value.kind_of?(Numeric) || callable_option_value?(value)
          raise callable_option_type_error ":#{key}", "a numeric value", value
        end
      end

      @constraints = options
    end

    def validate value, context, options = {}
      return unless value.kind_of? Numeric

      CHECKS.each_pair do |key,check|
        next unless check_value = actual_check_value(key, @constraints[key], options)
        next if value.send check, check_value
        context.add_error reason: REASONS[key], check_value: check_value, checked_value: value
      end
    end

    private

    def actual_check_value key, value, options
      actual_value = actual_option_value value, options
      raise callable_option_value_error ":#{key}", "a numeric value", value unless actual_value.kind_of? Numeric
      actual_value
    end
  end
