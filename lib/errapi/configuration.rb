class Errapi::Configuration
  attr_reader :plugins

  def initialize
    @plugins = []
    @validators = {}
    @conditions = {}
  end

  def new_context
    Errapi::ValidationContext.new plugins: @plugins
  end

  def register_validator name, factory
    @validators[name] = factory
  end

  def validator name, options = {}
    raise ArgumentError, "No validator factory registered for name #{name.inspect}" unless @validators.key? name
    @validators[name].new options
  end

  def register_condition factory
    factory.conditionals.each do |conditional|
      raise ArgumentError, "Conditional #{conditional} should start with 'if' or 'unless'." unless conditional.to_s.match /^(if|unless)/
      @conditions[conditional] = factory
    end
  end

  def extract_conditions! source, options = {}
    [].tap do |conditions|
      @conditions.each_pair do |conditional,factory|
        next unless source.key? conditional
        conditions << factory.new(conditional, source.delete(conditional), options)
      end
    end
  end
end
