require 'ostruct'
require File.join(File.dirname(__FILE__), 'plugin_system.rb')

module Errapi
  class ValidationContext
    include PluginSystem

    attr_reader :data
    attr_reader :errors

    def initialize options = {}
      @errors = []
      @data = OpenStruct.new options[:data] || {}
      initialize_plugins
    end

    # TODO: allow error creation to be configured
    def new_error options = {}
      OpenStruct.new options
    end

    def add_error options = {}, &block

      error = new_error options

      call_plugins :build_error, error, self, options

      yield error if block_given?

      @errors << error
      self
    end

    def validate value, options = {}
      return unless block_given?

      validation_options = options.dup

      call_plugins :build_validation_options, validation_options, self

      n = @errors.length

      if validate? value, validation_options
        yield value, self, validation_options
      end

      @errors.length <= n
    end

    def validate? value, options = {}
      @plugins.all?{ |plugin| !plugin.respond_to?(:validate?) || plugin.validate?(value, self, options) }
    end

    def errors? criteria = {}, &block
      return !@errors.empty? if criteria.empty? && !block
      block ? @errors.any?{ |err| error_matches_criteria?(err, criteria) && block.call(err) } : @errors.any?{ |err| error_matches_criteria?(err, criteria) }
    end

    def valid?
      !errors?
    end

    def clear
      @errors.clear
      @data = OpenStruct.new
    end

    def serialize options = {}
      result = []

      @errors.each do |error|
        serialized_error = {}

        call_plugins :serialize_error, error, serialized_error, self, options

        result << serialized_error
      end

      result
    end

    private

    # TODO: allow error matching to be configured
    def error_matches_criteria? error, criteria = {}
      criteria.all?{ |attr,criterion| error_attribute_matches_criterion? error, attr, criterion }
    end

    def error_attribute_matches_criterion? error, attr, criterion
      value = error[attr]

      if criterion.kind_of? Regexp
        !!criterion.match(value.to_s)
      elsif criterion.kind_of? String
        criterion == value.to_s
      elsif criterion.kind_of? Symbol
        criterion == value
      elsif criterion.respond_to? :match
        !!criterion.match(value)
      elsif criterion.respond_to? :===
        criterion === value
      else
        criterion == value
      end
    end
  end
end
