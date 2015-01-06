module Errapi
  class Error < StandardError; end
  class ValidationErrorInvalid < Error; end

  class ValidationFailed < Error
    attr_reader :context

    def initialize context
      super "A validation error occurred."
      @context = context
    end
  end
end
