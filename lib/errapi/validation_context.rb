module Errapi

  class ValidationContext
    attr_reader :errors

    def initialize
      @errors = []
    end

    def add message, options = {}
      @errors << ValidationError.new(message, options)
    end

    def error? criteria = {}
      return !@errors.empty? if criteria.empty?

      @errors.any? do |err|
        string_matches?(err, criteria, :message) &&
        value_matches?(err, criteria, :code) &&
        string_matches?(err, criteria, :type) &&
        string_matches?(err, criteria, :location)
      end
    end

    private

    def error_matches? err, criteria, attr, &block
      !criteria.key?(attr) || block.call(err.send(attr), criteria[attr])
    end

    def value_matches? err, criteria, attr
      error_matches?(err, criteria, attr){ |err_value,criterion| err_value == criterion }
    end

    def string_matches? err, criteria, attr
      error_matches?(err, criteria, attr){ |err_value,criterion| criterion.kind_of?(Regexp) ? !err_value.match(criterion).nil? : err_value == criterion }
    end
  end
end
