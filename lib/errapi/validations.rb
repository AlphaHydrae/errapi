module Errapi

  class Validations

    def initialize &block
      @validations = []
      @current_options = {}
      instance_eval &block if block
    end

    def validates *args, &block
      register_validations *args, &block
    end

=begin
    def validates_each *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      options[:with_context] ||= {}
      options[:with_context][:each] = args.shift
      options[:with_context][:each_with] = options.delete :each_with_context if options.key?(:each_with_context)
      args << options

      validates *args, &block
    end
=end

    def validate value, context, options = {}

      config = options.delete(:config) || Errapi.config

      @validations.each do |validation|

        context_options = validation[:context_options]

        target = validation[:target]

        context_options[:location] ||= target
        context_options[:location] = actual_location context_options

        context_options[:value_set] = true

        current_value = if target.respond_to? :call
          target.call value
        elsif value.kind_of?(Hash) && !target.nil?
          context_options[:value_set] = value.key? target
          value[target]
        elsif !target.nil? && value.respond_to?(target)
          value.send target
        elsif target.nil?
          value
        end

        with_options context_options do
          validator = validation[:validator] || config.validators[validation[:validator_name]].new
          validator.validate current_value, context, validation[:validator_options]
        end

        #next if validation[:conditions].any?{ |condition| !evaluate_condition(condition, context) }

        #validation_options = validation.dup

        #context.with validation_options.delete(:with_context) do
        #  validator(config, validation_options).validate context, validation_options
        #end
      end

      # TODO: add config option to raise error by default
      raise ValidationFailed.new(context.state) if options[:raise_error] && context.state.error?
    end

    def build_error error, context
      error.location = @current_options[:location].to_s
    end

    def build_current_data data, context
      data.value_set = !!@current_options[:value_set]
    end

    private

    def with_options options = {}
      original_options = @current_options
      @current_options = @current_options.merge options
      yield
      @current_options = original_options
    end

    def actual_location options = {}
      if options[:location]
        @current_location ? "#{@current_location}.#{options[:location]}" : options[:location]
      else
        @current_location
      end
    end

    def validator config, validation
      if validation[:validator]
        config.validators[validation[:validator]].new
      elsif validation[:using]
        validation[:using]
      end
    end

    def register_validations *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      context_options = options.delete(:with) || {}

      custom_validators = []
      custom_validators << options.delete(:using) if options[:using]
      custom_validators << Errapi::Validations.new(&block) if block

      #conditions = extract_conditions! options

      # TODO: fail if there are no validations declared
      args = [ nil ] if args.empty?

      args.each do |target|

        target = nil if target == self
        target_options = { target: target }

        unless custom_validators.empty?
          custom_validators.each do |custom_validator|
            @validations << { validator: custom_validator }.merge(target_options)
          end
        end

        options.each_pair do |validator_name,validator_options|
          next unless validator_options

          validator_options = validator_options.kind_of?(Hash) ? validator_options : {}
          #validator_options[:conditions] = conditions + extract_conditions!(validator_options)
          validator_context_options = validator_options.delete(:with) || context_options

          @validations << { validator_name: validator_name, validator_options: validator_options, context_options: validator_context_options }.merge(target_options)
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
