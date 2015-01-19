class Errapi::Plugins::Messages
  MESSAGES = {
    presence: {
      nil: 'This value cannot be null.',
      empty: 'This value cannot be empty.',
      blank: 'This value cannot be blank.'
    },
    string_length: {
      wrong_length: 'This string must be exactly %{constraint_length} characters long but has %{constrained_value}.',
      too_short: 'This string must be at least %{constraint_length} characters long but has only %{constrained_value}.',
      too_long: 'This string must be at most %{constraint_length} characters long but has %{constrained_value}.'
    }
  }

  def build_error error, context
    if !error.message && MESSAGES.key?(error.validator_name) && message = MESSAGES[error.validator_name][error.cause]

      %w(constraint_length constrained_value).each do |interpolated|
        if error.respond_to? interpolated
          message = message.gsub /\%\{#{interpolated}\}/, interpolated
        end
      end

      error.message = message
    end
  end
end
