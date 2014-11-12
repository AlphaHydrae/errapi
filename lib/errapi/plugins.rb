module Errapi

  module Plugins
  end

  module PluginFactory
    def plugin options = {}
      new options
    end
  end
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }
