module Errapi::Validator

  class Presence

    def validate value, context, options = {}, &block
      if value.respond_to?(:empty?) ? value.empty? : !value
        context.add_error({ message: 'This value cannot be null or empty.' }.merge(options), &block)
      end
    end
  end
end
