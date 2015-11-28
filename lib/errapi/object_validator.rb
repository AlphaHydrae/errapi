require File.join(File.dirname(__FILE__), 'plugin_system.rb')

module Errapi
  class ObjectValidator
    include PluginSystem

    def initialize options = {}, &block
      @validation_groups = []
      @registry = options[:registry]
      initialize_plugins options

      raise "A validation registry must be supplied with the :registry option" unless @registry

      instance_eval &block if block
    end

    def validates *args, &block
      options = args.last.kind_of?(Hash) ? args.pop : {}

      target = args.shift
      group = ValidationGroup.new target

      options.each_pair do |name,options|
        validation = @registry.validation name, options
        group.add validation
      end

      if block
        group.add ObjectValidator.new(registry: @registry, &block)
      end

      @validation_groups << group

      self
    end

    def validate value, context, options = {}
      @validation_groups.each do |group|
        group.validate value, context, options
      end
    end

    private

    class ValidationGroup
      attr_reader :validations

      def initialize target
        @target = target
        @validations = []
      end

      def add validation
        @validations << validation
      end

      def validate value, context, options = {}
        return unless has? value, @target

        target_value = extract value, @target

        @validations.each do |validation|
          validation.validate target_value, context, options
        end
      end

      def has? value, target
        target.nil? || target.respond_to?(:call) || value.kind_of?(Hash) || value.respond_to?(target)
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
end
