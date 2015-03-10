module Errapi::Plugins
  class Reason < Base
    plugin_name :reason

    attr_writer :config
    attr_accessor :camelize

    def serialize_error error, serialized
      serialized[:reason] = serialized_reason error
    end

    private

    def serialized_reason error
      camelize? ? Errapi::Utils.camelize(error.reason.to_s).to_sym : error.reason
    end

    def camelize?
      @camelize.nil? ? @config.options.camelize : @camelize
    end
  end
end
