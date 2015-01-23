class Errapi::Validations::Length
  CHECKS = { is: :==, minimum: :>=, maximum: :<= }.freeze
  REASONS = { is: :wrong_length, minimum: :too_short, maximum: :too_long }.freeze

  def initialize options = {}
    @constraints = actual_constraints options
  end

  def validate value, context, options = {}
    return unless value.respond_to? :length

    actual_length = value.length

    CHECKS.each_pair do |key,check|
      next unless check_value = @constraints[key]
      next if actual_length.send check, check_value
      context.add_error reason: REASONS[key], check_value: check_value, checked_value: actual_length, constraints: @constraints
    end
  end

  private

  def actual_constraints options = {}
    options.dup.tap do |actual|
      if range = actual.delete(:within)
        raise ArgumentError unless range.kind_of? Range
        actual[:minimum], actual[:maximum] = range.min, range.max
      end
    end
  end
end