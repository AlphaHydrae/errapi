module Errapi

  class ValidationContext
    attr_reader :errors

    def initialize config

      @config = config
      @errors = []

      @error_class = Class.new do
        config.plugins.each do |plugin|
          include plugin.const_get('ValidationErrorMixin') if plugin.const_defined? 'ValidationErrorMixin'
        end
      end
    end

    def add options = {}

      error = @error_class.new

      @config.plugins.each do |plugin|
        plugin.build_error error, options if plugin.respond_to? :build_error
      end

      yield error if block_given?

      @errors << error
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
