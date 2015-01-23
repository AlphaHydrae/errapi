require File.join(File.dirname(__FILE__), 'location_builders.rb')

module Errapi

  class ObjectValidator
    include LocationBuilders

    def initialize options = {}, &block

      @validations = []
      @config = options[:config] || Errapi.config

      instance_eval &block if block
    end

    def validates *args, &block
      register_validations *args, &block
    end

    def validates_each *args, &block

      options = args.last.kind_of?(Hash) ? args.pop : {}
      options[:each] = args.shift
      options[:each_options] = options.delete(:each_options) || {}
      args << options

      validates *args, &block
    end

    def validate value, context, options = {}
      # TODO: skip validation by default if previous errors at current location
      # TODO: add support for previous value and skip validation by default if value is unchanged

      return context.valid? unless @validations

      location = if options[:location]
        options[:location]
      elsif options[:location_type]
        builder = "#{options[:location_type]}_location"
        raise "Unknown location type #{options[:location_type].inspect}" unless respond_to? builder
        send builder
      else
        no_location
      end

      source = options[:source]
      context_proxy = ContextProxy.new context, self, location

      @validations.each do |validation_definition|

        each = validation_definition[:each]

        each_values = nil
        each_values_set = nil

        if each
          each_values = extract(value, each[:target], options)[:value]
          each_values_set = each_values.collect{ |v| true } if each_values.kind_of? Array
          each_values = [] unless each_values.kind_of? Array
          each_sources = each_values.collect{ |v| source }
        else
          each_values = [ value ]
          each_values_set = [ options.fetch(:value_set, true) ]
          each_sources = [ source ]
        end

        each_location = each ? location.relative(each[:options][:as] || each[:target]) : location

        each_values.each.with_index do |each_value,i|

          each_index_location = each ? each_location.relative(i) : location
          context_proxy.current_location = each_index_location

          next if validation_definition[:conditions].any?{ |condition| !condition.fulfilled?(each_value, context_proxy) }

          validation_definition[:validations].each do |validation|

            next if validation[:conditions] && validation[:conditions].any?{ |condition| !condition.fulfilled?(each_value, context_proxy) }

            validation_definition[:targets].each do |target|

              target_value_info = extract each_value, target, value_set: each_values_set[i], source: source

              validation_location = target ? each_index_location.relative(validation[:target_alias] || target) : each_index_location
              context_proxy.current_location = validation_location

              error_options = {
                value: target_value_info[:value],
                source: target_value_info[:source],
                value_set: target_value_info[:value_set],
                constraints: validation[:validation_options]
              }

              error_options[:location] = validation_location unless validation_location.kind_of? Errapi::Locations::None

              error_options[:validation] = validation[:validation_name] if validation[:validation_name]

              context_proxy.with_error_options error_options do
                validation_options = { location: validation_location, value_set: target_value_info[:value_set] }
                validation[:validation].validate target_value_info[:value], context_proxy, validation_options
              end
            end
          end
        end
      end

      # TODO: add config option to raise error by default
      raise Errapi::ValidationFailed.new(context) if options[:raise_error] && context.errors?

      context_proxy.valid?
    end

    def relative_location location
      RelativeLocation.new location
    end

    private

    class RelativeLocation
      attr_reader :location

      def initialize location
        @location = location
      end
    end

    def extract value, target, options = {}

      source = options[:source]
      value_set = options.fetch :value_set, true

      if target.nil?
        { value: value, value_set: value_set, source: source }
      elsif target.respond_to? :call
        { value: target.call(value), value_set: value_set, source: value }
      elsif value.kind_of? Hash
        { value: value[target], value_set: value.key?(target), source: value }
      elsif value.respond_to?(target)
        { value: value.send(target), value_set: value_set, source: value }
      else
        { value_set: false, source: value }
      end
    end

    def register_validations *args, &block
      # TODO: allow to set custom error options (e.g. reason) when registering validation

      options = args.last.kind_of?(Hash) ? args.pop : {}
      target_alias = options.delete :as

      validations_definition = {
        validations: []
      }

      # FIXME: register all validations (from :with, from block and from hash) in the order they are given
      if options[:with]
        validations_definition[:validations] += [*options.delete(:with)].collect{ |with| { validation: with, validation_options: {}, target_alias: target_alias } }
      end

      if block
        validations_definition[:validations] << { validation: self.class.new(config: @config, &block), validation_options: {}, target_alias: target_alias }
      end

      if options[:each]
        validations_definition[:each] = {
          target: options.delete(:each),
          options: options.delete(:each_options)
        }
      end

      validations_definition[:conditions] = @config.extract_conditions! options

      validations = options
      raise Errapi::ValidationDefinitionInvalid, "No validation was defined. Use registered validations (e.g. `presence: true`), the :with option, or a block to define validations." if validations_definition[:validations].empty? && validations.empty?

      validations.each do |validation_name,options|
        next unless options
        validation_options = options.kind_of?(Hash) ? options : {}
        validation_target_alias = validation_options.delete(:as) || target_alias
        conditions = @config.extract_conditions! validation_options
        validation = @config.validation validation_name, validation_options
        validations_definition[:validations] << { validation: validation, validation_name: validation_name, validation_options: validation_options, target_alias: validation_target_alias, conditions: conditions }
      end

      validations_definition[:targets] = args.empty? ? [ nil ] : args

      @validations << validations_definition
    end

    class ContextProxy
      instance_methods.each{ |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }
      attr_accessor :current_location

      def initialize context, validator, location
        @context = context
        @validator = validator
        @current_location = location
        @error_options = {}
      end

      def add_error options = {}, &block
        @context.add_error @error_options.merge(options), &block
      end

      def errors? criteria = {}, &block

        if criteria[:location].kind_of? RelativeLocation
          criteria = criteria.dup
          criteria[:location] = @current_location.relative criteria[:location].location
        end

        @context.errors? criteria, &block
      end

      # TODO: override errors? to support matching relative error locations

      def with_error_options error_options = {}, &block
        previous_error_options = @error_options
        @error_options = error_options
        block.call
        @error_options = previous_error_options
      end

      protected

      def method_missing name, *args, &block
        @context.send name, *args, &block
      end
    end
  end
end
