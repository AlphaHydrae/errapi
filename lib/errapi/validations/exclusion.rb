require File.join(File.dirname(__FILE__), 'clusivity.rb')

module Errapi::Validations
  class Exclusion < Base
    class Factory < ValidationFactory
      build Exclusion
    end

    include Clusivity

    def initialize options = {}
      unless key = exactly_one_option?(OPTIONS, options)
        raise ArgumentError, "Either :from or :in or :within must be supplied (but only one of them)."
      end

      @delimiter = options[key]
      check_delimiter! OPTIONS_DESCRIPTION
    end

    def validate value, context, options = {}
      excluded_values = members OPTIONS_DESCRIPTION, options
      if include? excluded_values, value
        context.add_error reason: :excluded, check_value: excluded_values
      end
    end

    private

    OPTIONS = %i(from in within)
    OPTIONS_DESCRIPTION = ":from (or :in or :within)"
  end
end
