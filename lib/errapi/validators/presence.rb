class Errapi::Validators::Presence

  def initialize options = {}
  end

  def validate value, context, options = {}
    if value_blank? value
      context.add_error message: :blank
    end
  end

  private

  BLANK_REGEXP = /\A[[:space:]]*\z/

  def value_blank? value
    if value.respond_to? :blank?
      value.blank?
    elsif value.kind_of? String
      BLANK_REGEXP === value
    elsif value.respond_to? :empty?
      value.empty?
    else
      !value
    end
  end
end
