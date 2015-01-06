class Errapi::Plugins::Messages
  MESSAGES = {
    presence: {
      blank: 'This value cannot be blank.'
    },
    length: {
      wrong_length: 'This value is not the right length.',
      too_short: 'This value is too short.',
      too_long: 'This value is too long.'
    }
  }

  def build_error error, context
    if error.message.kind_of?(Symbol) && MESSAGES.key?(error.validator_name) && message = MESSAGES[error.validator_name][error.message]
      error.message = message
    end
  end
end
