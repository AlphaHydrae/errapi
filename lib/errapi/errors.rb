module Errapi
  # TODO: check all "raise" statements and use custom errors
  class Error < StandardError; end
  class ValidationErrorInvalid < Error; end
  class ValidationDefinitionInvalid < Error; end

  class ValidationFailed < Error
    attr_reader :context

    def initialize context
      super "#{context.errors.length} errors were found during validation."
      @context = context
    end
  end
end
