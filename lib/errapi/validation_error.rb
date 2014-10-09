module Errapi

  class ValidationError
    attr_accessor :message, :code, :type, :location

    def initialize message, options = {}
      @message = message
      @code = options[:code]
      @type = options[:type]
      @location = options[:location]
    end
  end
end
