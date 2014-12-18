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
    error = plug :build_error, Errapi::ValidationError.new(options)

    yield error if block_given?

    @errors << error
    error
  end

  def with *args

    options = args.last.kind_of?(Hash) ? args.pop : {}

    original_plugins = @plugins

    unless args.empty? && options.empty?
      original_plugins = @plugins.dup

      @plugins = args + @plugins

      if options[:replace]
        options[:replace].each_pair do |original,replacement|
          @plugins.each.with_index do |plugin,i|
            @plugins[i] = replacement if plugin == original
          end
        end
      end
    end

    if block_given?
      yield
      @plugins = original_plugins
    end

    self
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
