module Errapi

  module Model

    def validate context, options = {}
      self.class.errapi.validate self, context, options
    end

    def Model.included mod
      mod.extend ClassMethods
    end

    module ClassMethods

      def errapi &block
        @errapi_validations ||= Validations.new(&block)
      end
    end
  end
end
