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
        if options[:each]
          values = extract options[:each], value
          values.each{ |value| perform_validation value, validation, context, config } if values.kind_of? Array
        else
          perform_validation value, validation, context, config
        end
      end
    end

    private

    def validator config, name
      config.validators[name].new
    end

    def perform_validation value, validation, context, config
      target = validation[:target]
      validator = validator config, validation[:validator]
      validator.validate extract(target, value), context, validation
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
          validator_options = validator_options.kind_of?(Hash) ? validator_options : {}
          @validations << validator_options.merge(validator: validator, target: target).merge(each_options)
        end
      end
    end
  end
end
