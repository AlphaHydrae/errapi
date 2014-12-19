class Errapi::Plugins::ErrorCodes
  CODES = {
    presence: {
      blank: 'blank'
    },
    length: {
      wrong_length: 'length.invalid',
      too_short: 'length.tooShort',
      too_long: 'length.tooLong'
    }
  }

  def build_error error, context
    if !error.code && CODES.key?(error.validator_name) && code = CODES[error.validator_name][error.message]
      error.code = code
    end
  end
end
