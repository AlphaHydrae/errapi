module Errapi::Validations
  module Clusivity

    def check_delimiter! option_description
      raise ArgumentError, "The #{option_description} option must be an object with the #include? method, a proc, a lambda or a symbol, but a #{@delimiter.class.name} was given." if IN_METHOD_CHECKS.none?{ |c| @delimiter.respond_to? c }
    end

    def members source

      enumerable = if @delimiter.respond_to? :call
        @delimiter.call source
      elsif @delimiter.respond_to? :to_sym
        source.send @delimiter
      else
        @delimiter
      end

      raise ArgumentError, "An enumerable must be returned from the given proc or lambda, or from calling the method corresponding to the given symbol, but a #{enumerable.class.name} was returned." unless enumerable.respond_to? :include?
      enumerable
    end

    def include? members, value
      members.send inclusion_method(members), value
    end

    private

    IN_METHOD_CHECKS = %i(include? call to_sym).freeze
  end
end
