module Errapi

  class ValidationContext
    attr_reader :state
    attr_accessor :current_type
    attr_accessor :current_location

    def initialize state
      @state = state
    end

    def add_error options = {}, &block

      context_options = {}

      context_options[:type] = @current_type if @current_type

      location = actual_location options
      context_options[:location] = location if location

      @state.add_error options.merge(context_options), &block
      self
    end

    def error? criteria = {}
      criteria[:location] = actual_location(criteria) if %i(location relative_location).any?{ |criterion| criteria.key? criterion }
      criteria.delete :relative_location
      @state.error? criteria
    end

    def with options = {}, &block

      if options.empty?
        yield
        return self
      end

      original_type = @current_type
      original_location = @current_location

      @current_type = options[:type] if options[:type]
      @current_location = actual_location options

      yield

      @current_type = original_type
      @current_location = original_location

      self
    end

    def validate value, options = {}
      if yield value, self, options
        true
      else
        add_error options[:error]
        false
      end
    end

    private

    def actual_location options = {}
      if options[:location]
        absolute_location options[:location]
      elsif options[:relative_location]
        @current_location ? relative_location(@current_location, options[:relative_location]) : absolute_location(options[:relative_location])
      else
        @current_location
      end
    end

    def absolute_location location
      location_to_string location
    end

    def relative_location base, relative
      "#{location_to_string(base)}.#{location_to_string(relative)}"
    end

    def location_to_string location
      location.kind_of?(Hash) && location.key?(:value) ? location[:value].to_s : location.to_s
    end
  end
end
