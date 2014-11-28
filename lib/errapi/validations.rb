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

    def validate context, options = {}

      config = options.delete(:config) || Errapi.config

      @validations.each do |validation|

        next if validation[:conditions].any?{ |condition| !evaluate_condition(condition, context) }

        context.with validation do

          # TODO: store validation options separately to override
          validator_options = validation.dup
          validator_options.delete :value
          validator_options.delete :previous_value
          validator_options.delete :type
          validator_options.delete :location
          validator_options.delete :relative_location

          validator(config, validation).validate context, validator_options
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

    def register_validations *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      validation_options = {}
      validation_options[:each] = options.delete :each if options[:each]
      validation_options[:each_with] = options.delete :each_with if options[:each_with]
      validation_options.merge! options.delete(:with_context) if options[:with_context]

      custom_validators = []
      custom_validators << options.delete(:using) if options[:using]
      custom_validators << Errapi::Validations.new(&block) if block

      conditions = extract_conditions! options

      # TODO: fail if there are no validations declared
      args = [ nil ] if args.empty?

      args.each do |target|

        target = nil if target == self

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
        conditions << { if_error: options.delete(:if_error) } if options[:if_error]
        conditions << { unless_error: options.delete(:unless_error) } if options[:unless_error]
      end
    end

    def evaluate_condition condition, context

      value = context.current_value

      conditional, condition_type, predicate = if condition.key? :if
        [ lambda{ |x| !!x }, :custom, condition[:if] ]
      elsif condition.key? :unless
        [ lambda{ |x| !x }, :custom, condition[:unless] ]
      elsif condition.key? :if_error
        [ lambda{ |x| !!x }, :error, condition[:if_error] ]
      elsif condition.key? :unless_error
        [ lambda{ |x| !x }, :error, condition[:unless_error] ]
      end

      result = case condition_type
      when :custom
        if predicate.kind_of?(Symbol) || predicate.kind_of?(String)
          value.respond_to?(:[]) ? value[predicate] : value.send(predicate)
        elsif predicate.respond_to? :call
          predicate.call value, self
        else
          predicate
        end
      when :error
        context.error? predicate
      end

      conditional.call result
    end
  end
end
