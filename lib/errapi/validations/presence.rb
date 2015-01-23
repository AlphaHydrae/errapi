class Errapi::Validations::Presence

  def initialize options = {}
  end

  def validate value, context, options = {}
    if reason = check(value, options.fetch(:value_set, true))
      context.add_error reason: reason
    end
  end

  private

  BLANK_REGEXP = /\A[[:space:]]*\z/

  def check value, value_set
    if !value_set
      :missing
    elsif value.nil?
      :null
    elsif value.respond_to?(:empty?) && value.empty?
      :empty
    elsif value_blank? value
      :blank
    end
  end

  def value_blank? value
    if value.respond_to? :blank?
      value.blank?
    elsif value.kind_of? String
      BLANK_REGEXP === value
    else
      false
    end
  end
end
