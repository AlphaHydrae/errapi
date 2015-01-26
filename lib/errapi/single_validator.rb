module Errapi

  class SingleValidator

    def self.configure *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      config = options[:config] || Errapi.config
      config = Errapi.config config if config.kind_of? Symbol

      @errapi_validator = ObjectValidator.new config, options, &block
    end

    def self.validate *args, &block
      raise "Validator has not yet been configured. You must call #configure before calling #validate." unless @errapi_validator
      @errapi_validator.validate *args, &block
    end
  end
end
