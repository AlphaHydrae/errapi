module Errapi
  class Error < StandardError; end
  class ValidationErrorInvalid < Error; end

  class ValidationFailed < Error
    attr_reader :state

    def initialize state
      super "A validation error occurred."
      @state = state
    end
  end
end
