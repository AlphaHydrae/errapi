module Errapi

  class ValidationError
    attr_accessor :message, :code, :type, :location

    def initialize options = {}
      set options
      yield self, options if block_given?
    end

    def set options = {}

      ATTRIBUTES.each do |attr|
        instance_variable_set "@#{attr}", options[attr]
      end

      self
    end

    def matches? criteria
      string_matches?(:message, criteria) ||
      string_matches?(:code, criteria) ||
      string_matches?(:type, criteria) ||
      string_matches?(:location, criteria)
    end

    def serializable_hash options = {}
      ATTRIBUTES.inject({}) do |memo,attr|
        value = instance_variable_get "@#{attr}"
        memo[attr] = value unless value.nil?
        memo
      end
    end

    private

    ATTRIBUTES = %i(message code type location)

    def string_matches? attr, criteria
      return false unless criteria.key? attr
      criteria[attr].kind_of?(Regexp) ? !!criteria[attr].match(send(attr)) : criteria[attr] == send(attr)
    end
  end
end
