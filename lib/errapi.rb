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
      config.validators[:presence] = Errapi::Validator::Presence
    end
  end
end
