class Errapi::Plugins::Messages
  MESSAGES = {
    presence: {
      nil: 'This value cannot be null.',
      empty: 'This value cannot be empty.',
      blank: 'This value cannot be blank.'
    },
    string_length: {
      wrong_length: 'This string must be exactly %{check_value} characters long but has %{checked_value}.',
      too_short: 'This string must be at least %{check_value} characters long but has only %{checked_value}.',
      too_long: 'This string must be at most %{check_value} characters long but has %{checked_value}.'
    }
  }

  def build_error error, context
    if !error.message && MESSAGES.key?(error.validation_name) && message = MESSAGES[error.validation_name][error.cause]

      %w(check_value checked_value).each do |interpolated|
        if error.respond_to? interpolated
          message = message.gsub /\%\{#{interpolated}\}/, interpolated
        end
      end

      error.message = message
    end
  end
end
