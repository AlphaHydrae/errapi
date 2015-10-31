module Errapi

  class Locations::Json

    def initialize location = nil
      @location = location.nil? ? '' : "/#{location.to_s.sub(/^\//, '')}"
    end

    def relative parts
      self.class.new "#{@location}/#{parts.to_s.sub(/^\//, '')}"
    end

    def location_type
      :json
    end

    def serialize
      @location
    end

    def === location
      @location.to_s == location.to_s
    end

    def to_s
      @location
    end
  end
end
