module Errapi::Validations
  class Numericality < Base
    class Factory < ValidationFactory
      build Numericality
    end

    def initialize options = {}

      # TODO: make checks work with callable options

      keys = options.keys.select{ |k| OPTIONS.include? k }
      if keys.empty?
        raise ArgumentError, "At least one option of #{OPTIONS.collect{ |o| ":#{o}" }.join(', ')} must be supplied."
      elsif keys.length >= 2 && (keys.include?(:equal_to) || keys.include?(:other_than))
        raise ArgumentError, "The :equal_to or :other_than options cannot be combined with other options or used together."
      elsif !keys.include?(:only_integer) && (keys.include?(:odd) || keys.include?(:even))
        raise ArgumentError, "The :odd and :even options require the :only_integer option to be set."
      elsif keys.include?(:greater_than) && keys.include?(:greater_than_or_equal_to)
        raise ArgumentError, "The :greater_than and :greater_than_or_equal_to options cannot be combined."
      elsif keys.include?(:less_than) && keys.include?(:less_than_or_equal_to)
        raise ArgumentError, "The :less_than and :less_than_or_equal_to options cannot be combined."
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
      # TODO: support strings

      keys = OPTIONS.select{ |k| @constraints.key? k }

      actual_constraints = keys.inject({}) do |memo,key|
        memo[key] = actual_check_value key, @constraints[key], options
        memo
      end

      if actual_constraints[:only_integer] && !value.kind_of?(Integer)
        context.add_error reason: :not_an_integer, constraints: actual_constraints
        return
      end

      # TODO: raise error if bounds are inconsistent (e.g. upper bound less than lower bound, odd and even)
      # TODO: reverse odd/even check if check value is false

      CHECKS.each_pair do |key,check|
        next unless check_value = actual_constraints[key]

        if NUMERIC_OPTIONS.include? key
          next if value.send check, check_value
        else
          next if value.send check
        end

        context.add_error reason: "not_#{key}".to_sym, check_value: check_value, checked_value: value, constraints: actual_constraints
      end
    end

    private

    CHECKS = { greater_than: :>, greater_than_or_equal_to: :>=,
               equal_to: :==, less_than: :<, less_than_or_equal_to: :<=,
               odd: :odd?, even: :even?, other_than: :!= }

    OPTIONS = CHECKS.keys + %i(only_integer)
    NUMERIC_OPTIONS = CHECKS.keys - %i(odd even)

    def actual_check_value key, value, options
      actual_value = actual_option_value value, options
      if NUMERIC_OPTIONS.include?(key) && !actual_value.kind_of?(Numeric)
        raise callable_option_value_error ":#{key}", "a numeric value", value
      end
      actual_value
    end
  end
end
