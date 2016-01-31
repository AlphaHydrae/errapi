module Errapi
  module PluginSystem

    def add_plugin plugin, options = {}
      plugin_name = options[:name]
      plugin_name ||= plugin.plugin_name if plugin.respond_to? :plugin_name
      raise "There is already a plugin named #{plugin_name}" if plugin_name && @plugins_by_name.key?(plugin_name.to_sym)

      @plugins << plugin
      @plugins_by_name[plugin_name.to_sym] = plugin if plugin_name

      self
    end

    def remove_plugin plugin, options = {}
      @plugins.delete plugin
      @plugins_by_name.delete_if{ |k,v| v == plugin }
      self
    end

    def plugin name
      @plugins_by_name[name.to_sym]
    end

    def plugin! name
      p = @plugins_by_name[name.to_sym]
      raise "No plugin named #{name}" unless p
      p
    end

    def yield_plugins operation, *args, &block
      yield_plugins_recursive @plugins.dup, operation, *args, &block
    end

    private

    def yield_plugins_recursive plugins, operation, *args, &block
      current_plugin = plugins.shift
      if current_plugin.nil?
        block.call
      elsif current_plugin.respond_to? operation
        current_plugin.send operation, *args do
          yield_plugins_recursive plugins, operation, *args, &block
        end
      else
        yield_plugins_recursive plugins, operation, *args, &block
      end
    end

    def initialize_plugins
      @plugins = []
      @plugins_by_name = {}
    end

    def call_plugins operation, *args
      @plugins.each do |plugin|
        plugin.send operation, *args if plugin.respond_to? operation
      end
    end
  end
end
