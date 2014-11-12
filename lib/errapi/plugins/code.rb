module Errapi::Plugins

  class Code
    extend Errapi::PluginFactory

    module ValidationErrorMixin
      attr_accessor :code
    end

    def initialize options = {}
    end

    def error_mixin
      ValidationErrorMixin
    end

    def build_error error, options
      raise Errapi::ValidationErrorInvalid, "The code of a validation error must be a string, but a #{options[:code].class} was given" if options.key?(:code) && !options[:code].kind_of?(String)
      error.code = options[:code]
    end

    def error_matches? error, criteria
      !criteria.key?(:code) || (criteria[:code].kind_of?(Regexp) ? !!criteria[:code].match(error.code) : error.code == criteria[:code])
    end
  end
end
