class Errapi::Plugins::ErrorCodes
  CODES = {
    presence: {
      nil: 'presence.nil',
      empty: 'presence.empty',
      blank: 'presence.blank'
    },
    string_length: {
      wrong_length: 'length.invalid',
      too_short: 'length.tooShort',
      too_long: 'length.tooLong'
    }
  }

  def build_error error, context
    if !error.code && CODES.key?(error.validation_name) && code = CODES[error.validation_name][error.cause]
      error.code = code
    end
  end
end
