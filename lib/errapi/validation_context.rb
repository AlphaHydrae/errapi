module Errapi

  class ValidationContext
    attr_reader :state

    def initialize state
      @state = state
    end

    def add_error options = {}, &block
      @state.add_error options, &block
      self
    end
  end
end
