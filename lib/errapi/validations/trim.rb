module Errapi::Validations
  class Trim < Base
    class Factory < ValidationFactory
      build Trim
    end

    def validate value, context, options = {}
      if value.kind_of?(String) && /(?:\A\s|\s\Z)/.match(value)
        context.add_error reason: :untrimmed
      end
    end
  end
end
