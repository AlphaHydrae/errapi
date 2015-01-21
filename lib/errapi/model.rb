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

      def errapi name = :default, &block
        @errapi_validators ||= {}
        @errapi_validators[name] = Errapi::ObjectValidator.new(&block) if block
        @errapi_validators[name]
      end
    end
  end
end
