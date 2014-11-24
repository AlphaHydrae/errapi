module Errapi
  VERSION = '0.1.0'
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }

module Errapi

  def self.config

    unless @config
      @config = Configuration.new
      @config.validators[:presence] = Errapi::Validators::Presence
    end

    @config
  end
end
