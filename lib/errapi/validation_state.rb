module Errapi

  class ValidationState
    attr_reader :errors

    def initialize
      @errors = []
    end

    def add_error options = {}, &block
      @errors << ValidationError.new(options, &block)
      self
    end

    def validate value, options = {}
      if yield value, options
        true
      else
        add_error options[:error]
        false
      end
    end

    def error? criteria = {}
      return !@errors.empty? if criteria.empty?
      @errors.any?{ |err| err.matches? criteria }
    end

    def valid?
      !error?
    end

    def clear
      @errors.clear
    end
  end
end
