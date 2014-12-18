class Errapi::ObjectValidations

  def initialize &block
    @validations = []
    @current_options = {}
    instance_eval &block if block
  end

  def validates *args, &block
    register_validations *args, &block
  end

  def validates_each *args, &block

    options = args.last.kind_of?(Hash) ? args.pop : {}
    options[:with] ||= {}
    options[:with][:each] = args.shift
    options[:with][:each_with] = options.delete :each_with if options.key? :each_with
    args << options

    validates *args, &block
  end

  def validate value, context, options = {}

    config = options.delete(:config) || Errapi.config

    context.with self do
      with_options options do

        @validations.each do |validation|

          context_options = validation[:context_options]
          each = context_options.delete :each
          each_with = context_options.delete(:each_with) || {}

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
          each_options[:location] = actual_location relative_location: each if each

          with_options each_options do

            values.each.with_index do |value,i|

              next if validation[:conditions].any?{ |condition| !evaluate_condition(condition, value, context) }

              iteration_options = {}
              iteration_options = { location: actual_location(relative_location: i), value_set: values_set[i] } if each

              with_options iteration_options do

                target = validation[:target]

                value_context_options = context_options.dup
                value_context_options[:location] = actual_location(extract_location(value_context_options) || { relative_location: target })

                value_data = extract value, target, value_set: values_set[i]
                current_value = value_data[:value]

                value_context_options[:value] = current_value
                value_context_options[:value_set] = value_data[:value_set]

                validator = validation[:validator] || config.validator(validation[:validator_name])
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
    criteria[:location] = actual_location criteria if %i(location relative_location).any?{ |k| criteria.key? k }
    criteria.delete :relative_location
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
    if options[:location]
      { location: options[:location] }
    elsif options[:relative_location]
      { relative_location: options[:relative_location] }
    end
  end

  def actual_location options = {}
    if options[:location]
      options[:location]
    elsif options[:relative_location]
      @current_options[:location] ? "#{@current_options[:location]}.#{options[:relative_location]}" : options[:relative_location]
    else
      @current_options[:location]
    end
  end

  def register_validations *args, &block

    options = args.last.kind_of?(Hash) ? args.pop : {}
    context_options = options.delete(:with) || {}

    custom_validators = []
    custom_validators << options.delete(:using) if options[:using] # TODO: allow array
    custom_validators << Errapi::ObjectValidations.new(&block) if block

    conditions = extract_conditions! options

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
          }.merge(target_options)
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
          context_options: validator_options.delete(:with) || context_options,
          conditions: conditions + extract_conditions!(validator_options)
        })

        @validations << validation.merge(target_options)
      end
    end
  end

  def extract_conditions! options = {}
    # TODO: wrap conditions in objects that can cache the result
    [].tap do |conditions|
      conditions << { if: options.delete(:if) } if options[:if]
      conditions << { unless: options.delete(:unless) } if options[:unless]
      conditions << { if_error: options.delete(:if_error) } if options[:if_error]
      conditions << { unless_error: options.delete(:unless_error) } if options[:unless_error]
    end
  end

  def evaluate_condition condition, value, context

    conditional, condition_type, predicate = if condition.key? :if
      [ lambda{ |x| !!x }, :custom, condition[:if] ]
    elsif condition.key? :unless
      [ lambda{ |x| !x }, :custom, condition[:unless] ]
    elsif condition.key? :if_error
      [ lambda{ |x| !!x }, :error, condition[:if_error] ]
    elsif condition.key? :unless_error
      [ lambda{ |x| !x }, :error, condition[:unless_error] ]
    end

    result = case condition_type
    when :custom
      if predicate.kind_of?(Symbol) || predicate.kind_of?(String)
        value.respond_to?(:[]) ? value[predicate] : value.send(predicate)
      elsif predicate.respond_to? :call
        predicate.call value, context, @current_options
      else
        predicate
      end
    when :error
      context.errors? predicate
    end

    conditional.call result
  end
end
