require 'ostruct'

class Errapi::ValidationContext
  attr_reader :data
  attr_reader :errors
  attr_reader :config

  def initialize options = {}
    @errors = []
    @data = OpenStruct.new options[:data] || {}
    @config = options[:config]
  end

  def add_error options = {}, &block

    error = options.kind_of?(Errapi::ValidationError) ? options : @config.new_error(options)
    yield error if block_given?
    @config.build_error error, self

    @errors << error
    self
  end

  def errors? criteria = {}, &block
    return !@errors.empty? if criteria.empty? && !block
    block ? @errors.any?{ |err| err.matches?(criteria) && block.call(err) } : @errors.any?{ |err| err.matches?(criteria) }
  end

  def valid?
    !errors?
  end

  def clear
    @errors.clear
    @data = OpenStruct.new
  end

  # TODO: add custom serialization options
  def serialize
    # TODO: add hook for plugins to serialize context
    { errors: [] }.tap do |h|
      @errors.each do |error|
        serialized = {}
        @config.serialize_error error, serialized
        h[:errors] << serialized
      end
    end
  end
end
