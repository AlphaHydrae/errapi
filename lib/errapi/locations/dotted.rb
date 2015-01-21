module Errapi

  class Locations::Dotted

    def initialize location = nil
      @location = location.to_s.sub /^\./, '' unless location.nil?
    end

    def relative parts
      if @location.nil?
        self.class.new parts
      else
        self.class.new "#{@location}.#{parts.to_s.sub(/^\./, '')}"
      end
    end

    def error_options
      @location.nil? ? {} : { location: @location, location_type: :dotted }
    end

    def serialize
      @location.nil? ? nil : @location
    end

    def to_s
      @location.to_s
    end
  end
end
