module Errapi

  class ValidationError
    attr_accessor :message, :code, :location, :location_type

    def initialize options = {}
      set options
      yield self, options if block_given?
    end

    def matches? criteria
      string_matches?(:message, criteria) ||
      string_matches?(:code, criteria) ||
      string_matches?(:location, criteria) ||
      string_matches?(:location_type, criteria)
    end

    def serializable_hash options = {}
      ATTRIBUTES.inject({}) do |memo,attr|
        value = instance_variable_get "@#{attr}"
        memo[attr] = value unless value.nil?
        memo
      end
    end

    private

    ATTRIBUTES = %i(message code location location_type).freeze

    def set options = {}
      ATTRIBUTES.each{ |attr| instance_variable_set "@#{attr}", options[attr] if options.key? attr }
    end

    def string_matches? attr, criteria
      return false unless criteria.key? attr
      criteria[attr].kind_of?(Regexp) ? !!criteria[attr].match(send(attr)) : criteria[attr] == send(attr)
    end
  end
end
