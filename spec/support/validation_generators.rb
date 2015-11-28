module ValidationGenerators
  def generate_validation &validation_block
    validation_class = Class.new do
      def self.validation_block
        @validation_block
      end

      def initialize options = {}, &validation_block
        @validation_options = options
      end

      def validate value, context, options = {}
        instance_exec value, context, options, &self.class.validation_block
      end
    end

    validation_class.instance_variable_set :@validation_block, validation_block
    validation_class
  end

  def generate_validation_factory name, validation_class
    factory = Class.new do
      def initialize name, validation_class
        @name = name
        @validation_class = validation_class
      end

      def name
        @name
      end

      def validation options = {}
        @validation_class.new options
      end
    end

    factory.new name, validation_class
  end
end
