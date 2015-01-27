module Errapi::Plugins
  class Location < Base
    plugin_name :location

    attr_writer :config
    attr_accessor :camelize

    def serialize_error error, serialized
      if error.location && error.location.respond_to?(:serialize)

        serialized_location = error.location.serialize
        unless serialized_location.nil?
          serialized[:location] = serialized_location
          serialized[location_type_key] = error.location.location_type if error.location.respond_to? :location_type
        end
      end
    end

    private

    def location_type_key
      camelize? ? :locationType : :location_type
    end

    def camelize?
      @camelize.nil? ? @config.options.camelize : @camelize
    end
  end
end
