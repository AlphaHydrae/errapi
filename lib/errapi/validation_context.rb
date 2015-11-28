require 'ostruct'

module Errapi
  class ValidationContext
    attr_reader :data
    attr_reader :errors
    attr_reader :plugins

    def initialize options = {}
      @errors = []
      @data = OpenStruct.new options[:data] || {}
      @plugins = options[:plugins] || []
    end

    def new_error options = {}
      # TODO: allow this to be configured
      OpenStruct.new options
    end

    def add_error options = {}, &block

      error = new_error options

      @plugins.each do |plugin|
        plugin.build_error error, self if plugin.respond_to? :build_error
      end

      yield error if block_given?

      @errors << error
      self
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
