module Errapi

  class Configuration

    def initialize
      @plugins = []
    end

    def plugin plugin
      @plugins << { source: plugin, type: :instance }
    end

    def plugin_factory factory
      @plugins << { source: factory, type: :factory }
    end

    def plugins_for_validation
      plugins = @plugins.collect do |definition|
        case definition[:type]
        when :factory
          definition[:source].plugin
        else
          definition[:source]
        end
      end
    end
  end
end
