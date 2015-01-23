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
    end

    def configure
      yield self
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
      name = options[:name] || Utils.underscore(impl.to_s.sub(/.*::/, '')).to_sym
      impl.config = self if impl.respond_to? :config=
      @plugins[name] = impl
    end

    def validation_factory factory, options = {}
      name = options[:name] || Utils.underscore(factory.to_s.sub(/.*::/, '')).to_sym
      factory.config = self if factory.respond_to? :config=
      @validation_factories[name] = factory
    end

    def validation name, options = {}
      raise ArgumentError, "No validation factory registered for name #{name.inspect}" unless @validation_factories.key? name
      factory = @validation_factories[name]
      factory.respond_to?(:validation) ? factory.validation(options) : factory.new(options)
    end

    def register_condition factory
      factory.conditionals.each do |conditional|
        raise ArgumentError, "Conditional #{conditional} should start with 'if' or 'unless'." unless conditional.to_s.match /^(if|unless)/
        @condition_factories[conditional] = factory
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

    def apply_plugins operation, *args
      @plugins.each_pair do |name,plugin|
        plugin.send operation, *args if plugin.respond_to? operation
      end
    end
  end
end
