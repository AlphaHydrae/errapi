module Errapi
  VERSION = '0.1.1'
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }

module Errapi

  def self.config
    @config ||= default_config
  end

  def self.default_config
    Configuration.new.tap do |config|
      config.plugins << Errapi::Plugins::ErrorCodes.new
      config.plugins << Errapi::Plugins::Messages.new
      config.register_validator :length, Errapi::Validators::Length
      config.register_validator :presence, Errapi::Validators::Presence
      config.register_condition Errapi::Condition::SimpleCheck
      config.register_condition Errapi::Condition::ErrorCheck
    end
  end
end
