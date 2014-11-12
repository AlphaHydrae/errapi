module Errapi

  class ValidationContext
    attr_reader :errors

    def initialize config
      @errors = []
      @plugins = config.plugins_for_validation
      @error_class = create_error_class
    end

    def add options = {}
      error = @error_class.new
      build_error error, options
      yield error if block_given?
      @errors << error
    end

    def error? criteria = {}
      return !@errors.empty? if criteria.empty?
      @errors.any?{ |err| error_matches? err, criteria }
    end

    private

    def create_error_class

      plugins = @plugins

      Class.new do
        plugins.each do |plugin|
          include plugin.error_mixin if plugin.respond_to? :error_mixin
        end
      end
    end

    def build_error error, options
      @plugins.each do |plugin|
        plugin.build_error error, options if plugin.respond_to? :build_error
      end
    end

    def error_matches? error, criteria
      @plugins.all?{ |plugin| plugin.respond_to?(:error_matches?) ? plugin.error_matches?(error, criteria) : true }
    end
  end
end
