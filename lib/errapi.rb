module Errapi
  VERSION = '0.1.2'
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }

module Errapi

  def self.configure *args, &block

    options = args.last.kind_of?(Hash) ? args.pop : {}
    name = args.shift || :default

    init_configs
    if @configs[name]
      raise ArgumentError, %/Configuration "#{name}" has already been configured./
    else
      @configs[name] = options[:config] || Configuration.new
    end

    if options.fetch :defaults, true
      default_config! @configs[name]
    end

    @configs[name].configure &block
  end

  def self.config name = nil
    init_configs[name || :default]
  end

  private

  def self.init_configs
    @configs ? @configs : @configs = {}
  end

  def self.default_config! config
    config.plugin Errapi::Plugins::I18nMessages.new
    config.plugin Errapi::Plugins::Reason.new
    config.plugin Errapi::Plugins::Location.new
    config.validation_factory Errapi::Validations::Exclusion::Factory.new
    config.validation_factory Errapi::Validations::Format::Factory.new
    config.validation_factory Errapi::Validations::Inclusion::Factory.new
    config.validation_factory Errapi::Validations::Length::Factory.new
    config.validation_factory Errapi::Validations::Presence::Factory.new
    config.validation_factory Errapi::Validations::Trim::Factory.new
    config.validation_factory Errapi::Validations::Type::Factory.new
    config.condition_factory Errapi::Condition::SimpleCheck
    config.condition_factory Errapi::Condition::ErrorCheck
  end
end
