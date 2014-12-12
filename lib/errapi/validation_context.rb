require 'ostruct'

module Errapi

  class ValidationContext
    attr_reader :handlers
    attr_reader :errors

    def initialize
      @errors = []
      @handlers = []
    end

    def add_error options = {}, &block

      options = options.dup

      @handlers.each do |handler|
        handler.build_error_options options, self if handler.respond_to? :build_error_options
      end

      error = ValidationError.new options

      @handlers.each do |handler|
        handler.build_error error, self if handler.respond_to? :build_error
      end

      yield error if block_given?

      @errors << error

      error
    end

    def data

      current_data = OpenStruct.new

      @handlers.each do |handler|
        handler.build_current_data current_data, self
      end

      current_data
    end

    def with *args

      options = args.last.kind_of?(Hash) ? args.pop : {}

      original_handlers = @handlers

      unless args.empty?
        original_handlers = @handlers.dup
        @handlers += args
      end

      if block_given?
        yield
        @handlers = original_handlers
      end

      self
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
      @data = OpenStruct.new
    end

    def value_set?
      !!@value_set
    end
  end
end
