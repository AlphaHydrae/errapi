module Errapi::Plugins

  module Message

    module ValidationErrorMixin
      attr_accessor :message
    end

    def self.build_error error, options
      error.message = options[:message]
    end

    def self.error_matches? error, criteria
      !criteria.key?(:message) || (criteria[:message].kind_of?(Regexp) ? !!error.message.match(criteria[:message]) : error.message == criteria[:message])
    end
  end
end
