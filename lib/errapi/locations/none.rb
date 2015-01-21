require 'singleton'

module Errapi

  class Locations::None
    include Singleton

    def relative parts
      self
    end

    def error_options
      {}
    end

    def serialize
      nil
    end

    def to_s
      LOCATION_STRING
    end

    private

    LOCATION_STRING = ''
  end
end
