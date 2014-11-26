module Errapi

  class Validations

    def initialize &block
      @validations = []
      instance_eval &block if block
    end

    def validates *args, &block
      register_validations *args, &block
    end

    def validates_each *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      options[:each] = args.shift
      args << options

      validates *args, &block
    end

    def validate value, context, options = {}

      config = options.delete(:config) || Errapi.config

      @validations.each do |validation|
        if validation[:each]

          values = extract validation[:each], value
          next unless values.kind_of? Array

          context_options = if validation[:each_with]
            validation[:each_with]
          elsif !validation[:each].respond_to?(:call)
            { relative_location: { type: :property, value: validation[:each] } }
          else
            {}
          end

          context.with context_options do
            values.each.with_index do |value,i|
              context.with relative_location: { type: :array_index, value: i } do
                perform_validation value, validation, context, config
              end
            end
          end
        else
          perform_validation value, validation, context, config
        end
      end
    end

    private

    def validator config, validation
      if validation[:validator]
        config.validators[validation[:validator]].new
      elsif validation[:using]
        validation[:using]
      end
    end

    def perform_validation value, validation, context, config

      return if validation[:conditions].any?{ |condition| !evaluate_condition(value, condition) }

      target = validation[:target]
      validator = validator config, validation

      context_options = if validation[:with]
        validation[:with]
      elsif !target.respond_to?(:call)
        { relative_location: target }
      else
        {}
      end

      context.with context_options do
        validator.validate extract(target, value), context, validation
      end
    end

    def evaluate_condition value, condition

      conditional, condition_value = if condition.key? :if
        [ lambda{ |x| !!x }, condition[:if] ]
      elsif condition.key? :unless
        [ lambda{ |x| !x }, condition[:unless] ]
      end

      result = if condition_value.kind_of? Symbol
        value.kind_of?(Hash) ? value[condition_value] : value.send(condition_value)
      elsif condition_value.respond_to? :call
        condition_value.call value
      end

      conditional.call result
    end

    def extract target, value
      if target.respond_to? :call
        target.call value
      elsif value.respond_to? :[]
        value[target]
      elsif target.nil?
        value
      elsif value.respond_to?(target)
        value.send target
      else
        nil # TODO: use singleton object to identify when extraction failed
      end
    end

    def register_validations *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      validation_options = {}
      validation_options[:each] = options.delete :each if options[:each]
      validation_options[:each_with] = options.delete :each_with if options[:each_with]
      validation_options[:with] = options.delete :with if options[:with]

      custom_validators = []
      custom_validators << options.delete(:using) if options[:using]
      custom_validators << Errapi::Validations.new(&block) if block

      conditions = extract_conditions! options

      # TODO: fail if there are no validations declared
      args = [ nil ] if args.empty?

      args.each do |target|

        unless custom_validators.empty?
          custom_validators.each do |custom_validator|
            @validations << { using: custom_validator, target: target, conditions: conditions.dup }.merge(validation_options)
          end
        end

        options.each_pair do |validator,validator_options|
          next unless validator_options
          validator_options = validator_options.kind_of?(Hash) ? validator_options : {}
          validator_options[:conditions] = conditions + extract_conditions!(validator_options)
          @validations << validator_options.merge(validator: validator, target: target).merge(validation_options)
        end
      end
    end

    def extract_conditions! options = {}
      # TODO: wrap conditions in objects that can cache the result
      [].tap do |conditions|
        conditions << { if: options.delete(:if) } if options[:if]
        conditions << { unless: options.delete(:unless) } if options[:unless]
      end
    end
  end
end
