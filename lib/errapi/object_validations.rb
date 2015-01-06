class Errapi::ObjectValidations

  def initialize options = {}, &block

    @validations = []
    @current_options = {}
    @config = options[:config] || Errapi.config

    instance_eval &block if block
  end

  def validates *args, &block
    register_validations *args, &block
  end

  def validates_each *args, &block

    options = args.last.kind_of?(Hash) ? args.pop : {}
    options[:each] = args.shift
    options[:each_options] = options.delete :each_options if options.key? :each_options
    args << options

    validates *args, &block
  end

  def validate value, context, options = {}

    context.with self do
      with_options options do

        @validations.each do |validation|

          context_options = validation[:context_options]
          each = validation[:each]
          each_options = validation[:each_options] || {}

          values = if each
            extract(value, each, options)[:value] || []
          else
            [ value ]
          end

          values_set = if each
            values.collect{ |v| true }
          else
            [ !!options[:value_set] ]
          end

          each_options = {}
          each_options[:location] = actual_location at_relative_location: each if each

          with_options each_options do

            values.each.with_index do |value,i|

              next if validation[:conditions].any?{ |condition| !condition.fulfilled?(value, context) }

              iteration_options = {}
              iteration_options = { location: actual_location(at_relative_location: i), value_set: values_set[i] } if each

              with_options iteration_options do

                target = validation[:target]

                value_context_options = context_options.dup
                value_context_options[:location] = actual_location(extract_location(value_context_options) || { at_relative_location: target })

                value_data = extract value, target, value_set: values_set[i]
                current_value = value_data[:value]

                value_context_options[:value] = current_value
                value_context_options[:value_set] = value_data[:value_set]

                validator = validation[:validator]
                value_context_options[:validator_name] = validation[:validator_name] if validation[:validator_name]
                value_context_options[:validator_options] = validation[:validator_options]

                with_options value_context_options do

                  handler_options = {}
                  handler_options[:replace] = { self => validator } if validator.kind_of? self.class

                  context.with handler_options do
                    validator_options = validation[:validator_options]
                    validator_options[:location] = @current_options[:location] if @current_options[:location]
                    validator_options[:value_set] = @current_options[:value_set] if @current_options.key? :value_set

                    validator.validate current_value, context, validator_options
                  end
                end
              end
            end
          end
        end
      end
    end

    # TODO: add config option to raise error by default
    raise ValidationFailed.new(context) if options[:raise_error] && context.errors?
  end

  def build_error error, context
    error.location = @current_options[:location].to_s
    %i(value_set validator_name validator_options).each do |attr|
      error[attr] = @current_options[attr] if @current_options.key? attr
    end
  end

  def build_error_criteria criteria, context

    if criteria[:at_absolute_location]
      criteria[:location] = criteria.delete :at_absolute_location
    elsif %i(at at_location at_relative_location at_absolute_location).any?{ |k| criteria.key? k }
      criteria[:location] = actual_location criteria
    end

    %i(at at_location at_relative_location at_absolute_location).each{ |key| criteria.delete key }
  end

  private

  def with_options options = {}
    original_options = @current_options
    @current_options = @current_options.merge options
    yield
    @current_options = original_options
  end

  def extract value, target, options = {}

    value_set = !!options[:value_set]

    if target.nil?
      { value: value, value_set: value_set }
    elsif target.respond_to? :call
      { value: target.call(value), value_set: value_set }
    elsif value.kind_of? Hash
      { value: value[target], value_set: value.key?(target) }
    elsif value.respond_to?(target)
      { value: value.send(target), value_set: value_set }
    else
      { value_set: false }
    end
  end

  def extract_location options = {}
    if options[:at_absolute_location]
      { at_absolute_location: options[:at_absolute_location] }
    elsif key = %i(at at_location at_relative_location).find{ |key| options.key? key }
      { key => options[key] }
    end
  end

  def actual_location options = {}
    if options[:at_absolute_location]
      options[:at_absolute_location]
    elsif key = %i(at at_location at_relative_location).find{ |key| options.key? key }
      @current_options[:location] ? "#{@current_options[:location]}.#{options[key]}" : options[key]
    else
      @current_options[:location]
    end
  end

  def extract_context_options! options = {}
    {}.tap do |h|
      %i(at at_location at_relative_location at_absolute_location).each do |key|
        h[key] = options.delete key if options.key? key
      end
    end
  end

  def register_validations *args, &block

    options = args.last.kind_of?(Hash) ? args.pop : {}
    context_options = extract_context_options! options

    custom_validators = []
    custom_validators << options.delete(:with) if options[:with] # TODO: allow array
    custom_validators << Errapi::ObjectValidations.new(&block) if block

    conditions = @config.extract_conditions! options

    each_options = {}
    each_options[:each] = options.delete :each if options[:each]
    each_options[:each_options] = options.delete :each_options if options[:each_options]

    # TODO: fail if there are no validations declared
    args = [ nil ] if args.empty?

    args.each do |target|

      target = nil if target == self
      target_options = { target: target }

      unless custom_validators.empty?
        custom_validators.each do |custom_validator|
          @validations << {
            validator: custom_validator,
            validator_options: {},
            context_options: context_options,
            conditions: conditions
          }.merge(target_options).merge(each_options)
        end
      end

      options.each_pair do |validator_name,validator_options|
        next unless validator_options

        validation = {
          validator_name: validator_name
        }

        validator_options = validator_options.kind_of?(Hash) ? validator_options : {}

        validation.merge!({
          validator_options: validator_options,
          context_options: context_options.merge(extract_context_options!(validator_options)),
          conditions: conditions + @config.extract_conditions!(validator_options)
        })

        validation[:validator] = @config.validator validator_name, validator_options

        @validations << validation.merge(target_options).merge(each_options)
      end
    end
  end
end
