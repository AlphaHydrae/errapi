module Errapi
  class Plugins::Reason
    class << self
      attr_writer :config
      attr_accessor :camelize

      def serialize_error error, serialized
        serialized[:reason] = serialized_reason error
      end

      private

      def serialized_reason error
        camelize? ? Utils.camelize(error.reason.to_s).to_sym : error.reason
      end

      def camelize?
        @camelize.nil? ? @config.options.camelize : @camelize
      end
    end
  end
end
