module Errapi::Validations
  class Exclusion
    include Clusivity

    def initialize options = {}
      @delimiter = options[:from] || options[:in] || options[:within]
      check_delimiter! ":from (or :in or :within)"
    end

    def validate value, context, options = {}
      allowed_values = members options[:source]
      if include? allowed_values, value
        context.add_error reason: :not_included, check_value: allowed_values
      end
    end
  end
end
