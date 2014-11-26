module Errapi

  class Validations

    def initialize &block
      @validations = []
      instance_eval &block if block_given?
    end

    def validates *args
      register_validations *args
    end

    def validates_each *args

      options = args.last.kind_of?(Hash) ? args.pop : {}
      options[:each] = args.shift

      args << options
      register_validations *args
    end

    def validate value, context, options = {}

      config = options.delete(:config) || Errapi.config

      @validations.each do |validation|
        if validation[:each]

          values = extract validation[:each], value
          next unless values.kind_of? Array

          context_options = {}
          context_options[:relative_location] = { type: :property, value: validation[:each] } unless validation[:each].respond_to?(:call)

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
      elsif validation[:with]
        validation[:with]
      end
    end

    def perform_validation value, validation, context, config

      target = validation[:target]
      validator = validator config, validation

      context_options = {}
      context_options[:relative_location] = target unless target.respond_to?(:call)

      context.with context_options do
        validator.validate extract(target, value), context, validation
      end
    end

    def extract target, value
      if target.respond_to? :call
        target.call value
      elsif value.respond_to? :[]
        value[target]
      elsif !target.nil?
        value.send target
      else
        value
      end
    end

    def register_validations *args

      options = args.last.kind_of?(Hash) ? args.pop : {}
      each_options = options[:each] ? { each: options.delete(:each) } : {}

      args = [ nil ] if args.empty?

      args.each do |target|
        options.each_pair do |validator,validator_options|

          next unless validator_options

          if validator == :with
            @validations << { with: validator_options, target: target }.merge(each_options)
          else
            validator_options = validator_options.kind_of?(Hash) ? validator_options : {}
            @validations << validator_options.merge(validator: validator, target: target).merge(each_options)
          end
        end
      end
    end
  end
end
