module Errapi::Validations
  class Length < Base
    class Factory < ValidationFactory
      build Length
    end

    CHECKS = { is: :==, minimum: :>=, maximum: :<= }.freeze
    REASONS = { is: :wrong_length, minimum: :too_short, maximum: :too_long }.freeze

    def initialize options = {}

      constraints = options.select{ |k,v| OPTIONS.include? k }
      if constraints.empty?
        raise ArgumentError, "The :is, :minimum/:maximum or :within options must be supplied (but only :minimum and :maximum can be used together)."
      elsif options.key?(:is) && constraints.length != 1
        raise ArgumentError, "The :is option cannot be combined with :minimum, :maximum or :within."
      elsif options.key?(:is)
        check_numeric! options[:is]
      elsif options.key?(:within)
        if options.key?(:minimum) || options.key?(:maximum)
          raise ArgumentError, "The :within option cannot be combined with :minimum or :maximum."
        else
          check_range! options[:within]
        end
      else
        check_numeric! options[:minimum] if options.key? :minimum
        check_numeric! options[:maximum] if options.key? :maximum
      end

      @constraints = actual_constraints constraints
    end

    def validate value, context, options = {}
      return unless value.respond_to? :length
      actual_length = value.length

      CHECKS.each_pair do |key,check|
        next unless check_value = @constraints[key]
        next if actual_length.send check, check_value
        context.add_error reason: REASONS[key], check_value: check_value, checked_value: actual_length, constraints: @constraints
      end
    end

    private

    OPTIONS = %i(is minimum maximum within)

    def actual_constraints options = {}
      if range = options[:within]
        { minimum: range.min, maximum: range.max }
      else
        options
      end
    end

    def check_numeric! bound
      unless bound.kind_of? Numeric
        raise ArgumentError, "The :is, :minimum or :maximum option must be a numeric value, but a #{bound.class.name} was given."
      end
    end

    def check_range! range
      if !range.kind_of?(Range)
        raise ArgumentError, "The :within option must be a numeric range, but a #{range.class.name} was given."
      elsif !(t = range.first).kind_of?(Numeric)
        raise ArgumentError, "The :within option must be a numeric range, but a #{t.class.name} range was given."
      end
    end
  end
end
