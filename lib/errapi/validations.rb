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
      options[:with_context] ||= {}
      options[:with_context][:each] = args.shift
      options[:with_context][:each_with] = options.delete :each_with_context if options.key?(:each_with_context)
      args << options

      validates *args, &block
    end

    def validate context, options = {}

      config = options.delete(:config) || Errapi.config

      @validations.each do |validation|

        next if validation[:conditions].any?{ |condition| !evaluate_condition(condition, context) }

        validation_options = validation.dup

        context.with validation_options.delete(:with_context) do
          validator(config, validation_options).validate context, validation_options
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
      context_options = options.delete(:with_context) || {}

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
            @validations << { using: custom_validator, conditions: conditions.dup, with_context: context_options.merge(target: target) }
          end
        end

        options.each_pair do |validator,validator_options|
          next unless validator_options

          validator_options = validator_options.kind_of?(Hash) ? validator_options : {}
          validator_options[:conditions] = conditions + extract_conditions!(validator_options)
          validator_options[:with_context] = context_options.merge(validator_options[:with_context] || {}).merge(target: target)

          @validations << validator_options.merge(validator: validator)
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
