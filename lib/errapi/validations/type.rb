module Errapi::Validations
  class Type

    def initialize options = {}

      keys = options.keys.select{ |k,v| OPTIONS.include? k }
      raise ArgumentError, "One option among :instance_of, :kind_of, :is_a or :is_an must be given (but only one)." if keys.length != 1

      if options.key? :instance_of
        @instance_of = check_type! options[:instance_of]
      else
        @kind_of = check_type! options[keys.first]
      end
    end

    def validate value, context, options = {}
      if @instance_of && !value.instance_of?(@instance_of)
        context.add_error reason: :wrong_type, check_value: @instance_of, checked_value: value.class
      elsif @kind_of && !value.kind_of?(@kind_of)
        context.add_error reason: :wrong_type, check_value: @kind_of, checked_value: value.class
      end
    end

    private

    def check_type! type
      raise ArgumentError, "A class or module is required, but a #{type.class} was given." unless TYPE_CLASSES.include? type.class
      type
    end

    OPTIONS = %i(instance_of kind_of is_a is_an)
    TYPE_CLASSES = [ Class, Module ]
  end
end
