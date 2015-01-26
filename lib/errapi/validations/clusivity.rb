module Errapi::Validations
  module Clusivity
    private

    DELIMITER_METHOD_CHECKS = %i(include? call to_sym).freeze

    def check_delimiter! option_description
      if DELIMITER_METHOD_CHECKS.none?{ |c| @delimiter.respond_to? c }
        raise ArgumentError, "The #{option_description} option must be an object with the #include? method, a proc, a lambda or a symbol, but a #{@delimiter.class.name} was given."
      end
    end

    def members source

      enumerable = if @delimiter.respond_to? :call
        @delimiter.call source
      elsif @delimiter.respond_to? :to_sym
        source.send @delimiter
      else
        @delimiter
      end

      unless enumerable.respond_to? :include?
        raise ArgumentError, "An enumerable must be returned from the given proc or lambda, or from calling the method corresponding to the given symbol, but a #{enumerable.class.name} was returned."
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
