module Errapi
  class ValidationRegistry
    attr_reader :validation_factories

    def initialize options = {}
      @validation_factories = {}
    end

    def add_validation_factory factory, options = {}
      name = implementation_name factory, options
      @validation_factories[name] = factory
    end

    def remove_validation_factory name
      raise ArgumentError, "No factory registered for name #{name.inspect}" unless @validation_factories.key? name
      @validation_factories.delete name
    end

    def validation name, options = {}
      raise ArgumentError, "No factory registered for name #{name.inspect}" unless @validation_factories.key? name
      factory = @validation_factories[name]
      factory.respond_to?(:validation) ? factory.validation(options) : factory.new(options)
    end

    def validate value, context, name, options = {}, runtime_options = {}
      validation(name, options).validate value, context, runtime_options
    end

    private

    def implementation_name impl, options = {}
      if options[:name]
        options[:name].to_sym
      elsif impl.respond_to? :name
        impl.name.to_sym
      else
        raise ArgumentError, "Factories must respond to #name or be supplied with the :name option."
      end
    end
  end
end
