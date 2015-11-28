module Errapi
  module PluginSystem
    def with plugins
      @previous_plugins = @plugins.dup
      yield if block_given?
      @plugins = @previous_plugins
    end

    private

    def initialize_plugins options = {}
      @plugins = options[:plugins] || {}
    end

    def call_plugins operation, *args
      @plugins.each_value do |plugin|
        plugin.send operation, *args if plugin.respond_to? operation
      end
    end
  end
end
