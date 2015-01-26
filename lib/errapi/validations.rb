module Errapi::Validations

  class Base

    def initialize options = {}
    end

    def actual_option_value supplied_value, options
      if supplied_value.respond_to? :call
        supplied_value.call options[:source]
      elsif supplied_value.respond_to? :to_sym
        unless options[:source].respond_to? supplied_value
          raise ArgumentError, "The validation source (#{options[:source].class.name}) does not respond to :#{supplied_value}."
        else
          options[:source].send supplied_value
        end
      else
        supplied_value
      end
    end

    def callable_option_value? supplied_value
      supplied_value.respond_to?(:call) || supplied_value.respond_to?(:to_sym)
    end

    def exactly_one_option? keys, options
      found_keys = options.keys.select{ |k| keys.include? k }
      found_keys.length == 1 ? found_keys.first : false
    end

    def callable_option_type_error key_desc, value_desc, supplied_value
      ArgumentError.new "The #{key_desc} option must be #{value_desc}, a proc, a lambda or a symbol, but a #{supplied_value.class.name} was given."
    end

    def callable_option_value_error key_desc, type_desc, supplied_value
      ArgumentError.new "The call supplied to #{key_desc} must return #{type_desc}, but a #{supplied_value.class.name} was returned."
    end
  end

  class Factory

    def config= config
      raise "A configuration has already been set for this factory." if @config
      @config = config
    end

    def validation options = {}
      self.class.const_get('Implementation').new options
    end

    def to_s
      Errapi::Utils.underscore self.class.name.sub(/.*::/, '')
    end
  end
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }
