require 'ostruct'

class Errapi::ValidationError
  attr_accessor :reason
  attr_accessor :check_value
  attr_accessor :checked_value
  attr_accessor :validation
  attr_accessor :constraints
  attr_accessor :location

  def initialize options = {}
    ATTRIBUTES.each do |attr|
      instance_variable_set "@#{attr}", options[attr] if options.key? attr
    end
  end

  def matches? criteria = {}
    unknown_criteria = criteria.keys - ATTRIBUTES
    raise "Unknown error attributes: #{unknown_criteria.join(', ')}." if unknown_criteria.any?
    ATTRIBUTES.all?{ |attr| criterion_matches? criteria, attr }
  end

  private

  ATTRIBUTES = %i(reason location check_value checked_value validation)

  def criterion_matches? criteria, attr
    return true unless criteria.key? attr

    criterion, value = criteria[attr], send(attr)

    if criterion.kind_of? Regexp
      !!criterion.match(value.to_s)
    elsif criterion.kind_of? String
      criterion == value.to_s
    elsif criterion.respond_to? :===
      criterion === value
    else
      criterion == value
    end
  end
end
