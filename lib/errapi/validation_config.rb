module Errapi

  class ValidationConfig
    attr_reader :options
    attr_reader :plugins

    def initialize
      @options = OpenStruct.new
      @plugins = OpenStruct.new
    end

    def build_error *args
      apply_plugins :build_error, *args
    end

    def new_context
      ValidationContext.new plugins: @plugins.to_h.values
    end

    def add_plugin impl, options = {}
      name = implementation_name impl, options
      impl.config = self if impl.respond_to? :config=
      @plugins[name] = impl
    end

    def remove_plugin name
      raise ArgumentError, "No plugin registered for name #{name.inspect}" unless @plugins.key? name
      @plugins.delete name
    end

    private

    def implementation_name impl, options = {}
      if options[:plugin_name]
        options[:plugin_name].to_sym
      elsif impl.respond_to? :plugin_name
        impl.plugin_name.to_sym
      else
        raise ArgumentError, "Added plugins must respond to #plugin_name or the :plugin_name option must be specified."
      end
    end

    def apply_plugins operation, *args
      @plugins.each_pair do |name,plugin|
        plugin.send operation, *args if plugin.respond_to? operation
      end
    end
  end
end
