require 'helper'

RSpec.describe 'errapi' do
  let(:context){ new_context }

  let :presence_validation_factory do
    presence = generate_validation do |value,context,options|
      context.add_error reason: :blank unless value
    end

    generate_validation_factory :presence, presence
  end

  let :custom_validation_factory do
    custom = generate_validation do |value,context,options|
      context.add_error @validation_options.dup
    end

    generate_validation_factory :custom, custom
  end

  it "should collect and find errors" do

    context.add_error foo: 'bar'
    context.add_error bar: 'baz'

    expect(context.errors?(foo: 'bar')).to be(true)
    expect(context.errors?(foo: 'baz')).to be(false)
    expect(context.errors?(bar: 'bar')).to be(false)
  end

  it "should register validations" do

    registry = Errapi::ValidationRegistry.new
    registry.add_validation_factory presence_validation_factory

    presence_validation = registry.validation :presence
    expect(presence_validation).not_to be_nil

    presence_validation.validate 'foo', context
    expect(context.errors?).to be(false)

    presence_validation.validate nil, context
    expect(context.errors?).to be(true)
    expect(context.errors?(reason: :blank)).to be(true)
  end

  it "should build validation groups" do

    registry = Errapi::ValidationRegistry.new
    registry.add_validation_factory presence_validation_factory
    registry.add_validation_factory custom_validation_factory

    validations = registry.validations presence: true, custom: { foo: :bar }

    context = new_context
    validations.validate nil, context

    expect(context.errors?).to be(true);
    expect(context).to have_errors([
      { reason: :blank },
      { foo: :bar }
    ])
  end

  it "should validate objects" do

    registry = Errapi::ValidationRegistry.new
    registry.add_validation_factory presence_validation_factory

    validator = Errapi::ObjectValidator.new registry: registry do
      validates :foo, presence: true
      validates :bar, presence: true do
        validates :baz, presence: true
      end
    end

    data = {}

    validator.validate data, context

    expect(context.errors?).to be(true)
    expect(context).to have_errors([
      { reason: :blank },
      { reason: :blank }
    ])
  end

  it "should serialize errors" do

    context.add_error foo: 'bar'
    context.add_error bar: 'baz'

    expect(context.serialize).to eq([ {}, {} ])

    serializer_class = Class.new do
      def serialize_error error, serialized, context, options = {}
        options.fetch(:only, []).each do |k|
          serialized[k] = error.send k if error.respond_to? k
        end
      end
    end

    context.plugins << serializer_class.new

    expect(context.serialize(only: %i(foo))).to eq([ { foo: 'bar' }, {} ])
    expect(context.serialize(only: %i(bar))).to eq([ {}, { bar: 'baz' } ])
    expect(context.serialize(only: %i(foo bar))).to eq([ { foo: 'bar' }, { bar: 'baz' } ])

    other_serializer_class = Class.new do
      def serialize_error error, serialized, context, options = {}
        serialized[:type] = :error
      end
    end

    context.plugins << other_serializer_class.new

    expect(context.serialize(only: %i(foo bar))).to eq([ { type: :error, foo: 'bar' }, { type: :error, bar: 'baz' } ])
  end

  def new_context
    Errapi::ValidationContext.new
  end
end
