module Errapi::Plugins
  class Base

    def self.plugin_name name = nil
      name ? @name = name : @name
    end

    def name
      self.class.name
    end
  end
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }
