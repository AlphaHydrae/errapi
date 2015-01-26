module Errapi::Validations
  class Type < Base

    def initialize options = {}
      unless key = exactly_one_option?(OPTIONS, options)
        raise ArgumentError, "One option among :instance_of, :kind_of, :is_a or :is_an must be supplied (but only one)."
      end

      if key == :instance_of
        @instance_of = check_types! options[key]
        raise ArgumentError, "Type aliases cannot be used with the :instance_of option. Use :kind_of, :is_a or :is_an." if options[key].kind_of? Symbol
      else
        @kind_of = check_types! options[key]
      end
    end

    def validate value, context, options = {}
      if @instance_of && @instance_of.none?{ |type| value.instance_of? type }
        context.add_error reason: :wrong_type, check_value: @instance_of, checked_value: value.class
      elsif @kind_of && @kind_of.none?{ |type| value.kind_of? type }
        context.add_error reason: :wrong_type, check_value: @kind_of, checked_value: value.class
      end
    end

    private

    def check_types! types
      if !types.kind_of?(Array)
        types = [ types ]
      elsif types.empty?
        raise ArgumentError, "At least one class or module is required, but an empty array was given."
      end

      types.each do |type|
        unless TYPE_ALIASES.key?(type) || type.class == Class || type.class == Module
          raise ArgumentError, "A class or module (or an array of classes or modules, or a type alias) is required, but a #{type.class} was given."
        end
      end

      types.collect{ |type| TYPE_ALIASES[type] || type }.flatten.uniq
    end

    OPTIONS = %i(instance_of kind_of is_a is_an)
    TYPE_ALIASES = {
      string: [ String ],
      number: [ Numeric ],
      integer: [ Integer ],
      boolean: [ TrueClass, FalseClass ],
      object: [ Hash ],
      array: [ Array ],
      null: [ NilClass ]
    }
  end
end
