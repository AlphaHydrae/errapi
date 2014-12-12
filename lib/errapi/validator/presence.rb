module Errapi::Validator

  class Presence

    def validate value, context, options = {}
      if value_blank? value
        context.add_error cause: :blank
      end
    end

    private

    BLANK_REGEXP = /\A[[:space:]]*\z/

    def value_blank? value
      if value.kind_of? String
        BLANK_REGEXP === value
      elsif value.respond_to?(:empty?)
        value.empty?
      else
        !value
      end
    end
  end
end
