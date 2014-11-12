module Errapi::Plugins

  class Message
    extend Errapi::PluginFactory

    module ValidationErrorMixin
      attr_accessor :message
    end

    def initialize options = {}
    end

    def error_mixin
      ValidationErrorMixin
    end

    def build_error error, options
      raise Errapi::ValidationErrorInvalid, "The message plugin requires validation errors to have a detail message, but none was given (options: #{options.keys.join(', ')})" if !options.key?(:message)
      raise Errapi::ValidationErrorInvalid, "The message of a validation error must be a string, but a #{options[:message].class} was given" if !options[:message].kind_of?(String)
      error.message = options[:message]
    end

    def error_matches? error, criteria
      !criteria.key?(:message) || (criteria[:message].kind_of?(Regexp) ? !!criteria[:message].match(error.message) : error.message == criteria[:message])
    end
  end
end
