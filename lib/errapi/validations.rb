module Errapi::Validations

  class Base

    def initialize options = {}
    end

    def option_value! supplied_value, source, expectation, &block

      actual_value = if supplied_value.respond_to? :call
        supplied_value.call source
      elsif supplied_value.respond_to? :to_sym
        source.send supplied_value
      else
        supplied_value
      end

      check_expectation! actual_value, expectation, &block
    end

    def check_callable_option_value! supplied_value, expectation, &block
      expectation_fulfilled = apply_expectation supplied_value, expectation
      raise ArgumentError, block.call(supplied_value) unless expectation_fulfilled || callable_option_value?(supplied_value)
      supplied_value
    end

    def check_expectation! supplied_value, expectation, &block
      expectation_fulfilled = apply_expectation supplied_value, expectation
      raise ArgumentError, block.call(supplied_value) unless expectation_fulfilled
      supplied_value
    end

    def apply_expectation value, expectation
      if expectation.kind_of? Symbol
        value.respond_to? expectation
      elsif expectation.class == Class || expectation.class == Module
        value.kind_of? expectation
      end
    end

    def callable_option_value? supplied_value
      supplied_value.respond_to?(:call) || supplied_value.respond_to?(:to_sym)
    end

    def check_exactly_one_option! keys, options, &block
      found_keys = options.keys.select{ |k| keys.include? k }
      raise ArgumentError, block.call(found_keys) if found_keys.length != 1
      found_keys.first
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
