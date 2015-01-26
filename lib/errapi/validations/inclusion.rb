require File.join(File.dirname(__FILE__), 'clusivity.rb')

module Errapi::Validations
  class Inclusion < Base
    include Clusivity

    def initialize options = {}
      unless key = exactly_one_option?(OPTIONS, options)
        raise ArgumentError, "Either :in or :within must be supplied (but not both)."
      end

      @delimiter = options[key]
      check_delimiter! OPTIONS_DESCRIPTION
    end

    def validate value, context, options = {}
      allowed_values = members OPTIONS_DESCRIPTION, options
      unless include? allowed_values, value
        context.add_error reason: :not_included, check_value: allowed_values
      end
    end

    private

    OPTIONS = %i(in within)
    OPTIONS_DESCRIPTION = ":in (or :within)"
  end
end
