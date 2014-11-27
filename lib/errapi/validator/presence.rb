module Errapi::Validator

  class Presence

    def validate context, options = {}, &block
      value = context.current_value
      if value.respond_to?(:empty?) ? value.empty? : !value
        context.add_error({ message: 'This value cannot be null or empty.' }.merge(options), &block)
      end
    end
  end
end
