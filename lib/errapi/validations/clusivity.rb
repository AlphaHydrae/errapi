module Errapi::Validations
  module Clusivity
    private

    DELIMITER_METHOD_CHECKS = %i(include? call to_sym).freeze

    def check_delimiter! option_desc
      unless @delimiter.respond_to?(:include?) || callable_option_value?(@delimiter)
        raise callable_option_type_error option_desc, "an object with the #include? method", @delimiter
      end
    end

    def members option_desc, options = {}
      enumerable = actual_option_value @delimiter, options

      unless enumerable.respond_to? :include?
        raise callable_option_value_error option_desc, "an object with the #include? method", @delimiter
      end

      enumerable
    end

    def include? members, value
      members.send inclusion_method(members), value
    end

    # From rails/activemodel/lib/active_model/validations/clusivity.rb:
    # In Ruby 1.9 <tt>Range#include?</tt> on non-number-or-time-ish ranges checks all
    # possible values in the range for equality, which is slower but more accurate.
    # <tt>Range#cover?</tt> uses the previous logic of comparing a value with the range
    # endpoints, which is fast but is only accurate on Numeric, Time, or DateTime ranges.
    def inclusion_method enumerable
      if enumerable.is_a? Range
        case enumerable.first
        when Numeric, Time, DateTime
          :cover?
        else
          :include?
        end
      else
        :include?
      end
    end
  end
end
