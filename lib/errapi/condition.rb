class Errapi::Condition
  ALLOWED_CONDITIONALS = %i(if unless).freeze

  def self.conditionals
    h = const_get('CONDITIONALS')
    raise LoadError, "The CONDITIONALS constant in class #{self} is of the wrong type (#{h.class}). Either make it a Hash or override #{self}.conditionals to return a list of symbols." unless h.kind_of? Hash
    h.keys
  end

  def initialize conditional, predicate, options = {}

    @conditional = resolve_conditional conditional
    raise ArgumentError, "Conditional must be either :if or :unless" unless ALLOWED_CONDITIONALS.include? @conditional

    @predicate = predicate
  end

  def fulfilled? *args
    result = check @predicate, *args
    result = !result if @conditional == :unless
    result
  end

  def resolve_conditional conditional
    conditional
  end

  def check predicate, value, context, options = {}
    raise NotImplementedError, "Subclasses should implement the #check method to check whether the value matches the predicate of the condition"
  end

  class SimpleCheck < Errapi::Condition

    CONDITIONALS = {
      if: :if,
      unless: :unless
    }.freeze

    def check predicate, value, context, options = {}
      if @predicate.kind_of?(Symbol) || @predicate.kind_of?(String)
        value.respond_to?(:[]) ? value[@predicate] : value.send(@predicate)
      elsif @predicate.respond_to? :call
        @predicate.call value, context, options
      else
        @predicate
      end
    end
  end

  class ErrorCheck < Errapi::Condition

    CONDITIONALS = {
      if_error: :if,
      unless_error: :unless
    }.freeze

    def resolve_conditional conditional
      CONDITIONALS[conditional]
    end

    def check predicate, value, context, options = {}
      if @predicate.respond_to? :call
        context.errors? &@predicate
      elsif @predicate.kind_of? Hash
        context.errors? @predicate
      else
        @predicate ? context.errors? : !context.errors?
      end
    end
  end
end
