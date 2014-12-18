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
      handle :build_error_options, options

      error = ValidationError.new options
      handle :build_error, error

      yield error if block_given?

      @errors << error

      error
    end

    def data

      current_data = OpenStruct.new
      handle :build_current_data, current_data

      current_data
    end

    def with *args

      options = args.last.kind_of?(Hash) ? args.pop : {}

      original_handlers = @handlers

      unless args.empty? && options.empty?
        original_handlers = @handlers.dup

        @handlers += args

        if options[:replace]
          options[:replace].each_pair do |original,replacement|
            @handlers.each.with_index do |handler,i|
              @handlers[i] = replacement if handler == original
            end
          end
        end
      end

      if block_given?
        yield
        @handlers = original_handlers
      end

      self
    end

    def error? criteria = {}, &block
      handle :build_error_criteria, criteria
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

    private

    def handle operation, value
      @handlers.each do |handler|
        handler.send operation, value, self if handler.respond_to? operation
      end
    end
  end
end
