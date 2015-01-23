module Errapi

  module LocationBuilders

    def json_location string = nil
      Locations::Json.new string
    end

    def dotted_location string = nil
      Locations::Dotted.new string
    end

    def no_location
      Locations::None.instance
    end
  end
end
