module Errapi::Validations
  class Inclusion
    include Clusivity

    def initialize options = {}
      @delimiter = options[:in] || options[:within]
      check_delimiter! ":in (or :within)"
    end

    def validate value, context, options = {}
      excluded_values = members options[:source]
      unless include? excluded_values, value
        context.add_error reason: :excluded, check_value: excluded_values
      end
    end
  end
end
