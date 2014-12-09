module Errapi

  class ValidationState
    attr_reader :errors

    def initialize
      @errors = []
    end

    def add_error options = {}, &block
      ValidationError.new(options, &block).tap do |error|
        @errors << error
      end
    end

    def error? criteria = {}, &block
      return !@errors.empty? if criteria.empty? && !block
      @errors.any?{ |err| err.matches?(criteria) && (!block || block.call(err)) }
    end

    def valid?
      !error?
    end

    def clear
      @errors.clear
    end
  end
end
