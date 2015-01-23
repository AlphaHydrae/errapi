module Errapi

  class Plugins::Location

    def serialize_error error, serialized
      if error.location && error.location.respond_to?(:serialize)

        serialized_location = error.location.serialize
        unless serialized_location.nil?
          serialized[:location] = serialized_location
          serialized[:location_type] = error.location.location_type if error.location.respond_to? :location_type
        end
      end
    end
  end
end
