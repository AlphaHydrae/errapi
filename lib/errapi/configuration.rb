module Errapi

  class Configuration
    attr_reader :plugins

    def initialize
      @plugins = []
    end

    def plugin plugin
      @plugins << plugin
    end
  end
end
