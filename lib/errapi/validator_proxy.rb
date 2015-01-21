module Errapi

  class ValidatorProxy
    instance_methods.each{ |m| undef_method m unless m =~ /(^__|^send$|^object_id$)/ }

    def initialize object, validator
      @object = object
      @validator = validator
    end

    def validate context, options = {}
      @validator.validate @object, context, options
    end

    protected

    def method_missing name, *args, &block
      @validator.send name, *args, &block
    end
  end
end
