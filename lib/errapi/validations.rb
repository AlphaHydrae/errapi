module Errapi

  class Validations

    def initialize &block
      @validations = []
      instance_eval &block if block_given?
    end

    def validates *args

      options = args.last.kind_of?(Hash) ? args.pop : {}
      general_options = options.delete(:all) || {}

      args = [ nil ] if args.empty?

      args.each do |target|
        options.each_pair do |validator,validator_options|
          if validator_options = validator_options.kind_of?(Hash) ? validator_options : {}
            @validations << general_options.merge(validator_options).merge(validator: validator, target: target)
          end
        end
      end
    end

    def validate value, context, options = {}

      config = options.delete(:config) || Errapi.config

      @validations.each do |validation|

        target = validation[:target]
        validator = validator config, validation[:validator]

        if target.respond_to? :call
          validator.validate target.call(value), context, validation
        elsif !target.nil?
          validator.validate value.send(target), context, validation
        else
          validator.validate value, context, validation
        end
      end
    end

    private

    def validator config, name
      config.validators[name].new
    end
  end
end
