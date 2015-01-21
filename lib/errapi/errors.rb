module Errapi
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
