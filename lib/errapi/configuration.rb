class Errapi::Configuration
  attr_reader :plugins

  def initialize
    @plugins = []
    @validators = {}
  end

  def new_context
    Errapi::ValidationContext.new plugins: @plugins
  end

  def register_validator name, validator
    raise ArgumentError, "The supplied object is not a validator (it does not respond to the #validate method)" unless validator.respond_to? :validate
    @validators[name] = validator
  end

  def validator name
    raise ArgumentError, "No validator found with name #{name.inspect}" unless @validators.key? name
    @validators[name]
  end
end
