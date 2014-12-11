module Errapi::Validator

  class Presence

    def validate context, options = {}
      if value_blank? context.value
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
