module Errapi
  module Model

    def validate *args

      options = args.last.kind_of?(Hash) ? args.pop : {}

      name, context = :default, args.shift
      if context.kind_of? Symbol
        name = context
        context = args.shift
      end

      validations = self.class.errapi name
      validations.validate self, context, options
    end

    def Model.included mod
      mod.extend ClassMethods
    end

    module ClassMethods

      def errapi name = nil, &block
        @errapi_validations ||= {}
        @errapi_validations[name || :default] ||= ObjectValidations.new(&block)
      end
    end
  end
end
