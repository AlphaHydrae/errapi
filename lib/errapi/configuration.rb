require File.join(File.dirname(__FILE__), 'utils.rb')

module Errapi

  class Configuration
    attr_reader :options
    attr_reader :plugins

    def initialize
      @options = OpenStruct.new
      @plugins = OpenStruct.new
      @validation_factories = {}
      @condition_factories = {}
      @location_factories = {}
      @configured = false
      @configured_blocks = []
    end

    def configured?
      @configured
    end

    def configure
      raise "Configuration can only be done once." if @configured
      yield self if block_given?
      @configured_blocks.each{ |block| block.call }
      @configured_blocks.clear
      @configured = true
      self
    end

    def on_configured &block
      if @configured
        block.call
      else
        @configured_blocks << block
      end
    end

    def new_error options = {}
      Errapi::ValidationError.new options
    end

    def build_error error, context
      apply_plugins :build_error, error, context
    end

    def serialize_error error, serialized
      apply_plugins :serialize_error, error, serialized
    end

    def new_context
      Errapi::ValidationContext.new config: self
    end

    def plugin impl, options = {}
      name = implementation_name impl, options
      impl.config = self if impl.respond_to? :config=
      @plugins[name] = impl
    end

    def remove_plugin name
      raise ArgumentError, "No plugin registered for name #{name.inspect}" unless @plugins.key? name
      @plugins.delete name
    end

    def validation_factory factory, options = {}
      name = implementation_name factory, options
      factory.config = self if factory.respond_to? :config=
      @validation_factories[name] = factory
    end

    def remove_validation_factory name
      raise ArgumentError, "No validation factory registered for name #{name.inspect}" unless @validation_factories.key? name
      @validation_factories.delete name
    end

    def validation name, options = {}
      raise ArgumentError, "No validation factory registered for name #{name.inspect}" unless @validation_factories.key? name
      factory = @validation_factories[name]
      factory.respond_to?(:validation) ? factory.validation(options) : factory.new(options)
    end

    def condition_factory factory
      factory.conditionals.each do |conditional|
        raise ArgumentError, "Conditional #{conditional} should start with 'if' or 'unless'." unless conditional.to_s.match /^(if|unless)/
        @condition_factories[conditional] = factory
      end
    end

    def remove_condition_factory factory
      factory.conditionals.each do |conditional|
        @condition_factories.delete conditional
      end
    end

    def extract_conditions! source, options = {}
      [].tap do |conditions|
        @condition_factories.each_pair do |conditional,factory|
          next unless source.key? conditional
          conditions << factory.new(conditional, source.delete(conditional), options)
        end
      end
    end

    private

    def implementation_name impl, options = {}
      if options[:name]
        options[:name].to_sym
      elsif impl.respond_to? :name
        impl.name.to_sym
      else
        raise ArgumentError, "Plugins and factories added to a configuration must respond to #name or be supplied with the :name option."
      end
    end

    def apply_plugins operation, *args
      @plugins.each_pair do |name,plugin|
        plugin.send operation, *args if plugin.respond_to? operation
      end
    end
  end
end
