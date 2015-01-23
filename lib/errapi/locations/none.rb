require 'singleton'

module Errapi

  class Locations::None
    include Singleton

    def relative parts
      self
    end

    def serialize
      nil
    end

    def === location
      location.nil? || self == location
    end

    def to_s
      LOCATION_STRING
    end

    private

    LOCATION_STRING = ''.freeze
  end
end
