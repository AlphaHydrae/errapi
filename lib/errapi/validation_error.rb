require 'ostruct'

class Errapi::ValidationError < OpenStruct

  def initialize options = {}
    super options
  end

  def matches? criteria = {}
    criteria.all?{ |key,value| value_matches? key, value }
  end

  def serializable_hash options = {}
    # TODO: handle :only and :except options
    to_h.select{ |k,v| !options.key?(:only) || options[:only].include?(k) }.reject{ |k,v| options[:except] && options[:except].include?(k) }
  end

  private

  def value_matches? attr, value
    value.kind_of?(Regexp) ? !!value.match(send(attr).to_s) : value == send(attr)
  end
end
