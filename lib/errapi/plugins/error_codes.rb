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
    if !error.code && error.validator_name && error.cause
      error.code ||= CODES[error.validator_name][error.cause]
    end
  end
end
