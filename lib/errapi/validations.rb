module Errapi::Validations
  class Factory

    def config= config
      raise "A configuration has already been set for this factory." if @config
      @config = config
    end

    def validation options = {}
      self.class.const_get('Implementation').new options
    end

    def to_s
      Errapi::Utils.underscore self.class.name.sub(/.*::/, '')
    end
  end
end

Dir[File.join File.dirname(__FILE__), File.basename(__FILE__, '.*'), '*.rb'].each{ |lib| require lib }
