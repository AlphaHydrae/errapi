require 'ostruct'

class Errapi::ValidationError
  attr_accessor :cause
  attr_accessor :check_value
  attr_accessor :checked_value
  attr_accessor :validation_name
  attr_accessor :validation_options
  attr_accessor :message
  attr_accessor :code
  attr_accessor :location
  attr_accessor :location_type

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

  def serializable_hash options = {}

    attrs = SERIALIZABLE_ATTRIBUTES
    attrs = attrs.select{ |attr| options[:only].include? attr } if options.key? :only
    attrs = attrs.reject{ |attr| options[:except].include? attr } if options.key? :except

    attrs.inject({}) do |memo,attr|
      value = send attr
      memo[attr] = value unless value.nil?
      memo
    end
  end

  private

  SERIALIZABLE_ATTRIBUTES = %i(message code location location_type)
  ATTRIBUTES = %i(cause check_value checked_value validation_name) + SERIALIZABLE_ATTRIBUTES

  def criterion_matches? criteria, attr
    return true unless criteria.key? attr
    value = criteria[attr]
    value.kind_of?(Regexp) ? !!value.match(send(attr).to_s) : value == send(attr)
  end
end
