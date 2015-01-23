module Errapi

  class Locations::Json

    def initialize location = nil
      @location = location.nil? ? '' : "/#{location.to_s.sub(/^\//, '').sub(/\/$/, '')}"
    end

    def relative parts
      if @location.nil?
        self.class.new parts
      else
        self.class.new "#{@location}/#{parts.to_s.sub(/^\./, '').sub(/\/$/, '')}"
      end
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
