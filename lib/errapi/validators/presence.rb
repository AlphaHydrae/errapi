module Errapi::Validators

  class Presence

    def validate value, context, options = {}, &block
      unless value.respond_to?(:empty) ? !value.empty? : !value.nil?
        context.add_error({ message: 'This value cannot be null or empty.' }.merge(options), &block)
      end
    end
  end
end
