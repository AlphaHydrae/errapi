module Errapi::Validator

  class Length
    CHECKS = { is: :==, minimum: :>=, maximum: :<= }.freeze
    CAUSES = { is: :wrong_length, minimum: :too_short, maximum: :too_long }.freeze

    def validate value, context, options = {}
      return unless value.respond_to? :length

      options = actual_constraints options
      actual_length = value.length

      CHECKS.each_pair do |key,check|
        next unless check_value = options[key]
        next if actual_length.send check, check_value
        context.add_error cause: CAUSES[check]
      end
    end

    private

    def actual_constraints options = {}
      options.dup.tap do |actual|
        if range = actual.delete(:within)
          raise ArgumentError unless range.kind_of? Range
          actual[:minimum], actual[:maximum] = range.min, range.max
        end
      end
    end
  end
end
