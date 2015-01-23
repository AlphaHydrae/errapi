require 'i18n'

# TODO: support interpolating source and target name (e.g. "Project name cannot be null.")
class Errapi::Plugins::I18nMessages
  class << self

    def serialize_error error, serialized
      return if serialized.key? :message

      if I18n.exists? translation_key = "errapi.#{error.reason}"
        interpolation_values = INTERPOLATION_KEYS.inject({}){ |memo,key| memo[key] = error.send(key); memo }.reject{ |k,v| v.nil? }
        serialized[:message] = I18n.t translation_key, interpolation_values
      end
    end

    private

    INTERPOLATION_KEYS = %i(check_value checked_value)
  end
end
