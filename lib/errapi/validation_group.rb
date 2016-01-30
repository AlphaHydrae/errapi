module Errapi
  class ValidationGroup
    attr_reader :validations

    def initialize validations
      @validations = validations
    end

    def validate value, context, options = {}
      @validations.each do |validation|
        validation.validate value, context, options
      end
    end
  end
end
