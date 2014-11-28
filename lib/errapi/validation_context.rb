module Errapi

  class ValidationContext
    attr_reader :state
    attr_accessor :current_value
    attr_accessor :current_previous_value
    attr_accessor :current_type
    attr_accessor :current_location

    def initialize state, options = {}
      @state = state
      set_properties! options
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

      options = options.dup
      original_properties = current_properties

      if options[:each]
        each = options.delete :each

        elements = extract each, @current_value
        unless elements.kind_of? Array
          restore_properties!
          return self
        end

        context_options = if options[:each_with]
          options.delete :each_with
        elsif !each.respond_to?(:call)
          { relative_location: { type: :property, value: each } }
        else
          {}
        end

        run_with original_properties, context_options do

          intermediate_properties = current_properties

          elements.each.with_index do |element,i|
            run_with intermediate_properties, { value: element, relative_location: { type: :array_index, value: i } } do
              run_with current_properties, options, &block
            end
          end
        end
      else
        run_with original_properties, options, &block
      end

      self
    end

    private

    PROPERTIES = %i(current_value current_previous_value current_type current_location)

    def run_with original_properties, options = {}, &block

      target = options[:target]

      if target
        @current_value = extract target, @current_value
        @current_previous_value = extract target, @current_previous_value
        if %i(location relative_location).none?{ |key| options.key? key }
          options[:relative_location] = target
        end
      end

      set_properties! options

      if block_given?
        yield
        restore_properties! original_properties
      end
    end

    def set_properties! properties = {}
      @current_value = properties[:value] if properties.key? :value
      @current_previous_value = properties[:previous_value] if properties.key? :previous_value
      @current_type = properties[:type] if properties.key? :type
      @current_location = actual_location properties
    end

    def current_properties
      PROPERTIES.inject({}){ |memo,p| memo[p] = instance_variable_get("@#{p}"); memo }
    end

    def restore_properties! properties
      PROPERTIES.each{ |p| instance_variable_set "@#{p}", properties[p] }
    end

    def extract target, value
      if value.nil?
        nil
      elsif target.respond_to? :call
        target.call value
      elsif value.respond_to? :[]
        value[target]
      elsif target.nil?
        value
      elsif value.respond_to?(target)
        value.send target
      else
        nil # TODO: use singleton object to identify when extraction failed
      end
    end

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
