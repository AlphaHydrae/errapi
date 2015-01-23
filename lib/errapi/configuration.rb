class Errapi::Configuration
  attr_reader :plugins

  def initialize
    @plugins = []
    @validation_factories = {}
    @condition_factories = {}
    @location_factories = {}
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

  def register_validation name, factory
    @validation_factories[name] = factory
  end

  def validation name, options = {}
    raise ArgumentError, "No validation factory registered for name #{name.inspect}" unless @validation_factories.key? name
    @validation_factories[name].new options
  end

  def register_location name, factory
    @location_factories[name] = factory
  end

  def location name, initial_location = nil
    raise ArgumentError, "No location factory registered for name #{name.inspect}" unless @location_factories.key? name
    @location_factories[name].new initial_location
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
    @plugins.each do |plugin|
      plugin.send operation, *args if plugin.respond_to? operation
    end
  end
end
