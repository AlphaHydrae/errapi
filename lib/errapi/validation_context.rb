module Errapi

  class ValidationContext
    attr_reader :state
    attr_accessor :value
    attr_accessor :location
    attr_accessor :location_type

    def initialize *args

      options = args.last.kind_of?(Hash) ? args.pop : {}
      set_properties! options

      # TODO: state should be required
      @state = args.shift || ValidationState.new
    end

    def add_error options = {}, &block

      context_options = {}

      if @location
        context_options[:location] = @location
        context_options[:location_type] = @location_type
      end

      @state.add_error options.merge(context_options), &block
      self
    end

    def error? criteria = {}
      @state.error? criteria
    end

    def with options = {}, &block

      if options.empty?
        yield if block_given?
        return self
      end

      original_properties = current_properties
      set_properties! options

      if block_given?
        yield
        set_properties! original_properties
      end

      self
    end

    private

    PROPERTIES = %i(value location location_type)

    def set_properties! properties = {}
      PROPERTIES.each{ |p| instance_variable_set "@#{p}", properties[p] if properties.key? p }
    end

    def current_properties
      PROPERTIES.inject({}){ |memo,p| memo[p] = instance_variable_get("@#{p}"); memo }
    end
  end
end
