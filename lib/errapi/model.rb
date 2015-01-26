module Errapi

  module Model

    def errapi name = :default
      validator = self.class.errapi name
      ValidatorProxy.new self, validator
    end

    def self.included mod
      mod.extend ClassMethods
    end

    module ClassMethods

      def errapi *args, &block

        options = args.last.kind_of?(Hash) ? args.pop : {}
        config = options[:config] || Errapi.config
        config = Errapi.config config if config.kind_of? Symbol

        name = args.shift || :default

        @errapi_validators ||= {}
        @errapi_validators[name] = Errapi::ObjectValidator.new(config, &block) if block
        @errapi_validators[name]
      end
    end
  end
end
