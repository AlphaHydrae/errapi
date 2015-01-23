class Errapi::Plugins::I18nMessages
  MESSAGES = {
    array_length: {
      wrong_length: 'This array must contain exactly %{check_value} elements but has %{checked_value} elements.',
      too_short: 'This array must contain at least %{check_value} elements but has only %{checked_value} elements.',
      too_long: 'This array must contain at most %{check_value} elements but has %{checked_value} elements.'
    },
    presence: {
      nil: 'This value cannot be null.',
      empty: 'This value cannot be empty.',
      blank: 'This value cannot be blank.'
    },
    string_length: {
      wrong_length: 'This string must be exactly %{check_value} characters long but has %{checked_value} characters.',
      too_short: 'This string must be at least %{check_value} characters long but has only %{checked_value} characters.',
      too_long: 'This string must be at most %{check_value} characters long but has %{checked_value} characters.'
    },
    type: {
      wrong_type: 'This value is of the wrong type.'
    }
  }

  def _disabled_build_error error, context
    if !error.message && MESSAGES.key?(error.validation) && message = MESSAGES[error.validation][error.reason]

      %w(check_value checked_value).each do |interpolated|
        if error.respond_to? interpolated
          message = message.gsub /\%\{#{interpolated}\}/, interpolated
        end
      end

      error.message = message
    end
  end
end
