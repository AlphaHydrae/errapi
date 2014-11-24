module Errapi

  class ValidationContext
    attr_reader :errors

    def initialize
      @errors = []
    end

    def add_error options = {}, &block
      @errors << ValidationError.new(options, &block)
    end

    def error? criteria = {}
      return !@errors.empty? if criteria.empty?
      @errors.any?{ |err| err.matches? criteria }
    end
  end
end
