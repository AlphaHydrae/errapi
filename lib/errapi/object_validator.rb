require File.join(File.dirname(__FILE__), 'plugin_system.rb')

module Errapi
  class ObjectValidator

    def initialize options = {}, &block
      @target_validation_groups = []
      @registry = options[:registry]
      @navigator = Errapi::Plugins::Navigator.new

      raise "A validation registry must be supplied with the :registry option" unless @registry

      instance_eval &block if block
    end

    def validates *args, &block
      options = args.last.kind_of?(Hash) ? args.pop : {}

      target = args.shift

      validations = @registry.validations options

      if block
        validations.validations << ObjectValidator.new(registry: @registry, &block)
      end

      @target_validation_groups << TargetValidationGroup.new(target, validations)

      self
    end

    def validate value, context, options = {}
      context.plugins << @navigator

      @target_validation_groups.each do |group|
        @navigator.navigate @target do
          @navigator.validate group, context, options
        end
      end

      context.plugins.delete @navigator
    end

    private

    class TargetValidationGroup
      attr_reader :target

      def initialize target, validations
        @target = target
        @validations = validations
      end

      def validate value, context, options = {}
        @validations.validate value, context, options
      end
    end
  end
end
