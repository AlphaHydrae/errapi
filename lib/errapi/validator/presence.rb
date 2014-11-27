module Errapi::Validator

  class Presence

    def validate context, options = {}, &block
      puts "current location in validator = #{context.current_location}"
      puts "options in validator = #{options}"
      value = context.current_value
      if value.respond_to?(:empty?) ? value.empty? : !value
        context.add_error({ message: 'This value cannot be null or empty.' }.merge(options), &block)
      end
    end
  end
end
