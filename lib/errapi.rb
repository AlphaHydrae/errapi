module Errapi
  VERSION = '0.1.1'
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }

module Errapi

  def self.configure name = nil, &block

    init_configs
    name ||= :default

    if @configs[name]
      @configs[name].configure &block
    else
      @configs[name] = Configuration.new &block
    end
  end

  def self.config name = nil
    init_configs[name || :default]
  end

  private

  def self.init_configs
    @configs ? @configs : @configs = { default: default_config }
  end

  def self.default_config
    Configuration.new.tap do |config|
      config.plugin Errapi::Plugins::I18nMessages
      config.plugin Errapi::Plugins::Reason
      config.plugin Errapi::Plugins::Location
      config.register_validation :length, Errapi::Validations::Length
      config.register_validation :presence, Errapi::Validations::Presence
      config.register_validation :type, Errapi::Validations::Type
      config.register_condition Errapi::Condition::SimpleCheck
      config.register_condition Errapi::Condition::ErrorCheck
    end
  end
end
