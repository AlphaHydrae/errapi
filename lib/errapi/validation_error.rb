module Errapi

  class ValidationError
    attr_accessor :message, :code, :type, :location

    def initialize options = {}
      set options
      yield self, options if block_given?
    end

    def set options = {}

      %i(message code type location).each do |attr|
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

    private

    def string_matches? attr, criteria
      return false unless criteria.key? attr
      criteria[attr].kind_of?(Regexp) ? !!criteria[attr].match(send(attr)) : criteria[attr] == send(attr)
    end
  end
end
