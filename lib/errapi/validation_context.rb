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

    private

    def actual_location options
      if options[:location]
        options[:location]
      elsif options[:relative_location]
        @current_location ? "#{@current_location}.#{options[:relative_location]}" : options[:relative_location]
      else
        @current_location
      end
    end
  end
end
