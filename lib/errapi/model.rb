module Errapi::Model

  def validate *args

    options = args.last.kind_of?(Hash) ? args.pop : {}

    name, context = :default, args.shift
    if context.kind_of? Symbol
      name = context
      context = args.shift
    end

    validator = self.class.errapi name
    validator.validate self, context, options
  end

  def self.included mod
    mod.extend ClassMethods
  end

  module ClassMethods

    def errapi name = :default, &block
      @errapi_validators ||= {}
      @errapi_validators[name] = Errapi::ObjectValidator.new(&block) if block
      @errapi_validators[name]
    end
  end
end
