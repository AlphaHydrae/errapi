module Errapi
  module PluginSystem

    def add_plugin plugin, options = {}
      plugin_name = options[:name]
      plugin_name ||= plugin.name if plugin.respond_to? :name
      raise "Plugin must respond to :name or be given with the :name option" unless plugin_name
      raise "There is already a plugin named #{plugin_name}" if @plugins.key? plugin_name.to_sym
      @plugins[plugin_name.to_sym] = plugin
      self
    end

    def plugins
      @plugins_view
    end

    private

    def initialize_plugins
      @plugins = {}
      @plugins_view = PluginsView.new @plugins
    end

    def call_plugins operation, *args
      @plugins.each_value do |plugin|
        plugin.send operation, *args if plugin.respond_to? operation
      end
    end

    class PluginsView
      def initialize plugins
        @plugins = plugins
      end

      def respond_to? symbol
        super(symbol) || @plugins.include?(symbol.to_sym)
      end

      def method_missing symbol, *args, &block
        if @plugins.include?(symbol.to_sym) && args.empty?
          @plugins[symbol.to_sym]
        else
          super symbol, *args, &block
        end
      end
    end
  end
end
