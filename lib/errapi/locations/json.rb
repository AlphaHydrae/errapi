module Errapi

  class Locations::Json

    def initialize location = nil
      @location = location.nil? ? '' : location.to_s.sub(/^\//, '').sub(/\/$/, '')
    end

    def relative parts
      if @location.nil?
        self.class.new parts
      else
        self.class.new "#{@location}/#{parts.to_s.sub(/^\./, '').sub(/\/$/, '')}"
      end
    end

    def error_options
      { location: @location, location_type: :json }
    end

    def serialize
      @location
    end

    def to_s
      @location
    end
  end
end
