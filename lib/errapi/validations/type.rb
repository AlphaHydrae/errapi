class Errapi::Validations::Type

  def initialize options = {}
    @type = options[:kind_of]
  end

  def validate value, context, options = {}
    unless value.kind_of? @type
      context.add_error cause: :wrong_type
    end
  end
end
