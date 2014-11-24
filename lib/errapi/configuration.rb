module Errapi

  class Configuration
    attr_reader :validators

    def initialize
      @validators = {}
    end
  end
end
