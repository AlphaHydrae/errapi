require 'helper'

RSpec.describe 'errapi' do
  let(:context){ Errapi::ValidationContext.new }

  let :presence_validation_factory do
    presence = generate_validation do |value,context,options|
      context.add_error reason: :blank unless value
    end

    generate_validation_factory :presence, presence
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
    registry.add_validation_factory Errapi::Validations::Presence::Factory.new

    presence_validation = registry.validation :presence
    expect(presence_validation).not_to be_nil

    presence_validation.validate 'foo', context
    expect(context.errors?).to be(false)

    presence_validation.validate nil, context
    expect(context.errors?).to be(true)
    expect(context.errors?(reason: :null)).to be(true)
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
    expect(context.errors).to have(2).items

    expect(context.errors[0]).to eq(OpenStruct.new(reason: :blank))
    expect(context.errors[1]).to eq(OpenStruct.new(reason: :blank))
  end
end
