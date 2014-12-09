module Errapi::Validator

  class Presence

    def validate context, options = {}, &block
      value = context.current_value
      if value.respond_to?(:empty?) ? value.empty? : !value
        context.add_error(options.merge(cause: :blank, context: context.dup), &block)
      end
    end
  end
end
