module Errapi::Plugins
  class Navigator < Base
    plugin_name :location

    attr_reader :current_value
    attr_reader :current_metadata

    def initialize
      @current_metadata = {}
    end

    def plugin_name
      :navigator
    end

    def set_value value, metadata = {}
      @current_value = value
      @current_metadata = metadata
      self
    end

    def with value, metadata = {}

      swap_value = @current_value
      swap_metadata = @current_metadata

      @current_value = value
      @current_metadata = metadata

      yield

      @current_value = swap_value
      @current_metadata = swap_metadata

      self
    end

    def navigate context, *args
      options = args.last.kind_of?(Hash) ? args.pop : {}

      nav_type = :access
      target = options.key?(:target) ? options.delete(:target) : args.shift

      if %i(each each_key each_value).include?(target) && args.length == 1
        nav_type = target
        target = args.shift
      elsif !args.empty?
        raise "Invalid navigation arguments"
      end

      value_has_target = has? @current_value, target
      new_value = extract @current_value, target
      new_metadata = @current_metadata.merge options.dup

      if nav_type == :access && @current_metadata.fetch(:value_set, true)
        new_metadata[:value_set] ||= value_has_target
        context.yield_plugins :around_navigate, context, nav_type, target do
          with new_value, new_metadata do
            yield
          end
        end
      elsif nav_type == :each && new_value.kind_of?(Array)
        new_metadata[:value_set] = true
        new_value.each.with_index do |value,i|
          context.yield_plugins :around_navigate, context, nav_type, target, i do
            with new_value[i], new_metadata.merge(value_index: i) do
              yield
            end
          end
        end
      elsif nav_type == :each_key && new_value.respond_to?(:each_key)
        new_metadata[:value_set] = true
        new_value.each_key do |key|
          context.yield_plugins :around_navigate, context, nav_type, target, key do
            with key, new_metadata do
              yield
            end
          end
        end
      elsif nav_type == :each_value && new_value.respond_to?(:each_value)
        new_metadata[:value_set] = true
        new_value.each_pair do |key,value|
          context.yield_plugins :around_navigate, context, nav_type, target, key do
            with value, new_metadata.merge(value_key: key) do
              yield
            end
          end
        end
      else
        self
      end
    end

    def validate validation, context, options = {}
      validation.validate @current_value, context, options
    end

    def build_validation_options options, context
      options.merge! @current_metadata
    end

    private

    METADATA_OPTIONS = %i(value_set)

    def has? value, target
      target.nil? || target.respond_to?(:call) || (value.kind_of?(Hash) && value.key?(target)) || value.respond_to?(target)
    end

    def extract value, target
      if target.nil?
        value
      elsif target.respond_to? :call
        target.call value
      elsif value.kind_of? Hash
        value[target]
      elsif value.respond_to? target
        value.send target
      end
    end
  end
end
