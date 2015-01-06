require 'ostruct'

class Errapi::ValidationContext
  attr_reader :data
  attr_reader :plugins
  attr_reader :errors

  def initialize options = {}
    @errors = []
    @plugins = options[:plugins] || []
    @data = OpenStruct.new
  end

  def add_error options = {}, &block

    options = plug :build_error_options, options.dup
    error = Errapi::ValidationError.new options

    yield error if block_given?

    error = plug :build_error, error

    @errors << error
    error
  end

  def errors? criteria = {}, &block
    plug :build_error_criteria, criteria
    return !@errors.empty? if criteria.empty? && !block
    @errors.any?{ |err| err.matches?(criteria) && (!block || block.call(err)) }
  end

  def valid?
    !errors?
  end

  def clear
    @errors.clear
    @data = OpenStruct.new
  end

  private

  def plug operation, value

    @plugins.each do |plugin|
      plugin.send operation, value, self if plugin.respond_to? operation
    end

    value
  end
end
