require 'ostruct'

module Errapi

  class ValidationError < OpenStruct

    def initialize options = {}
      super options
    end

    def matches? criteria = {}
      criteria.all?{ |key,value| value_matches? key, value }
    end

    def serializable_hash options = {}
      # TODO: handle :only and :except options
      to_h
    end

    private

    def value_matches? attr, value
      value.kind_of?(Regexp) ? !!value.match(send(attr).to_s) : value == send(attr)
    end
  end
end
