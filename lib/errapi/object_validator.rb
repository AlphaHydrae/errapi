require File.join(File.dirname(__FILE__), 'plugin_system.rb')

module Errapi
  class ObjectValidator

    def initialize options = {}, &block
      @target_validation_groups = []
      @registry = options[:registry]

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

      navigator = options[:navigator]
      if navigator
        validate_targets navigator, context, options
      else
        navigator = Errapi::Plugins::Navigator.new
        context.add_plugin navigator

        navigator.with value do
          validate_targets navigator, context, options
        end

        context.remove_plugin navigator
      end
    end

    private

    def validate_targets navigator, context, options
      @target_validation_groups.each do |group|
        navigator.navigate context, group.target do
          navigator.validate group, context, options.merge(navigator: navigator)
        end
      end
    end

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
