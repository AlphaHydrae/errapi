module Errapi

  class SingleValidator

    def self.configure options = {}, &block
      raise "Validator has already been configured. You must call this method before #validate or the various #validates methods." if @errapi_validator
      @errapi_validator = ObjectValidator.new options, &block
    end

    def self.validates *args, &block
      init_validator.validates *args, &block
    end

    def self.validates_each *args, &block
      init_validator.validates_each *args, &block
    end

    def self.validate *args, &block
      init_validator.validate *args, &block
    end

    private

    def self.init_validator
      @errapi_validator ||= ObjectValidator.new
    end
  end
end
