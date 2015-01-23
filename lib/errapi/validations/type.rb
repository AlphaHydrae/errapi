class Errapi::Validations::Type

  def initialize options = {}
    @type = options[:kind_of]
  end

  def validate value, context, options = {}
    unless value.kind_of? @type
      context.add_error reason: :wrong_type, check_value: @type, checked_value: value.class.name
    end
  end
end
