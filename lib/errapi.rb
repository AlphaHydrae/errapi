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
      config.register_validation :array_length, Errapi::Validations::ArrayLength
      config.register_validation :string_length, Errapi::Validations::StringLength
      config.register_validation :presence, Errapi::Validations::Presence
      config.register_validation :type, Errapi::Validations::Type
      config.register_condition Errapi::Condition::SimpleCheck
      config.register_condition Errapi::Condition::ErrorCheck
      config.register_location :dotted, Errapi::Locations::Dotted
      config.register_location :json, Errapi::Locations::Json
    end
  end
end
