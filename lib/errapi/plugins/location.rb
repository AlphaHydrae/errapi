module Errapi::Plugins
  class Location < Base
    plugin_name :location

    attr_accessor :current_location
    attr_accessor :current_location_type

    def with location, location_type = nil

      swap_location = @current_location
      swap_location_type = @current_location_type

      @current_location = location
      @current_location_type = location_type if location_type

      yield

      @current_location = swap_location
      @current_location_type = swap_location_type

      self
    end

    def build_error error, context, options = {}
      location = effective_location options
      if location
        error.location = location

        location_type = effective_location_type options
        error.location_type = location_type if location_type
      end
    end

    def validate? value, context, options = {}
      location = effective_location options
      return true unless location

      search_options = { location: location }
      location_type = effective_location_type
      search_options[:location_type] = location_type if location_type

      !context.errors?(search_options)
    end

    def serialize_error error, serialized, *args
      if error.respond_to?(:location) && error.location
        serialized[:location] = error.location
        serialized[:locationType] = error.location_type if error.respond_to?(:location_type) && error.location_type
        serialized[:locationType] = error.location.type if error.location.respond_to?(:location_type) && error.location.location_type
      end
    end

    private

    def effective_location options = {}
      options.fetch :location, @current_location
    end

    def effective_location_type options = {}
      options.fetch :location_type, @current_location_type
    end
  end
end
