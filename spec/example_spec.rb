require 'helper'

RSpec.describe 'errapi' do

  let(:context){ Errapi.config.new_context }

  it "should collect and find errors" do

    context.add_error reason: 'foo'
    context.add_error reason: 'bar', validation: 'yeehaw'
    context.add_error{ |err| err.reason = 'baz'; err.validation = "rock'n'roll" }

    %w(foo bar baz).each do |reason|
      expect(context.errors?(reason: reason)).to be(true)
    end

    [ /fo/, /ba/ ].each do |regexp|
      expect(context.errors?(reason: regexp)).to be(true)
    end

    expect(context.errors?(reason: 'qux')).to be(false)
    expect(context.errors?(reason: /qux/)).to be(false)

    %w(yeehaw rock'n'roll).each do |validation|
      expect(context.errors?(validation: validation)).to be(true)
    end

    [ /^yee/, /k'n'r/ ].each do |regexp|
      expect(context.errors?(validation: regexp)).to be(true)
    end

    expect(context.errors?(validation: 'broken')).to be(false)
    expect(context.errors?(validation: /broke/)).to be(false)
  end

  it "should provide a model extension to validate objects" do

    klass = Class.new do
      include Errapi::Model

      attr_accessor :name, :age

      errapi do
        validates :name, presence: true
      end

      errapi :with_age do
        validates :name, presence: true
        validates Proc.new(&:age), presence: true, as: 'age'
      end
    end

    o = klass.new
    o.errapi.validate context, location_type: :dotted
    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'name')).to be(true)
    expect(context.errors).to have(1).item

    context.clear
    o.name = 'foo'
    o.errapi.validate context, location_type: :dotted
    expect(context.errors?).to be(false)

    context.clear
    o.name = nil
    o.errapi(:with_age).validate context, location_type: :dotted
    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'name')).to be(true)
    expect(context.errors?(location: 'age')).to be(true)
    expect(context.errors).to have(2).items
  end

  it "should validate parsed JSON" do

    h = {
      foo: 'bar',
      bar: {},
      baz: [
        { a: 'b' },
        { a: 'c' },
        { a: nil },
        { a: 'd' },
        {}
      ]
    }

    bar_validations = Errapi::ObjectValidator.new do
      validates :foo, presence: true
    end

    validations = Errapi::ObjectValidator.new do

      validates :foo, presence: true
      validates :bar, with: bar_validations
      validates :qux, presence: true
      validates_each :baz, :a, presence: true

      validates :bar do
        validates :baz, presence: true
      end

      validates :bar, as: 'corge' do
        validates :qux, presence: true, as: 'grault'
      end
    end

    validations.validate h, context, location_type: :dotted

    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'bar.foo')).to be(true)
    expect(context.errors?(location: 'qux')).to be(true)
    expect(context.errors?(location: 'baz.2.a')).to be(true)
    expect(context.errors?(location: 'baz.4.a')).to be(true)
    expect(context.errors?(location: 'bar.baz')).to be(true)
    expect(context.errors?(location: 'corge.grault')).to be(true)
    expect(context.errors).to have(6).items
  end

  it "should conditionally execute validations based on custom conditions" do

    h = {
      foo: 'bar',
      bar: {}
    }

    validations = Errapi::ObjectValidator.new do
      validates :baz, presence: { if: :baz }
      validates :qux, presence: { if: Proc.new{ |h| h[:foo] == 'baz' } }
      validates :corge, presence: { unless: :bar }
      validates :grault, presence: { unless: Proc.new{ |h| h[:foo] == 'bar' } }
      validates :garply, presence: true, if: :baz
      validates if: :baz do
        validates :waldo, presence: true
      end
    end

    validations.validate h, context, location_type: :dotted

    expect(context.errors?).to be(false)
    expect(context.errors).to be_empty

    h = {
      foo: 'baz',
      baz: []
    }

    validations.validate h, context, location_type: :dotted

    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'baz')).to be(true)
    expect(context.errors?(location: 'qux')).to be(true)
    expect(context.errors?(location: 'corge')).to be(true)
    expect(context.errors?(location: 'grault')).to be(true)
    expect(context.errors?(location: 'garply')).to be(true)
    expect(context.errors?(location: 'waldo')).to be(true)
    expect(context.errors).to have(6).items
  end

  it "should conditionally execute validations based on previous errors" do

    h = {
      foo: 'bar',
      bar: false,
      qux: {}
    }

    validations = Errapi::ObjectValidator.new do
      validates :foo, presence: true
      validates :bar, presence: true, if_error: { location: dotted_location('foo') }
      validates :baz, presence: { unless_error: { location: dotted_location('foo') } }
      validates :qux do
        validates :corge, presence: { unless_error: { location: 'foo' } }
        validates :grault, presence: { if_error: { location: 'qux.corge' } }
        validates :garply, presence: { if_error: { location: relative_location('corge') } }
        validates :waldo, presence: true, if_error: { location: json_location('foo') }
      end
    end

    validations.validate h, context, location_type: :dotted

    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'baz')).to be(true)
    expect(context.errors?(location: 'qux.corge')).to be(true)
    expect(context.errors?(location: 'qux.grault')).to be(true)
    expect(context.errors?(location: 'qux.garply')).to be(true)
    expect(context.errors).to have(4).item

    h = {
      foo: nil,
      qux: {}
    }

    context.clear
    validations.validate h, context, location_type: :dotted

    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'foo')).to be(true)
    expect(context.errors?(location: 'bar')).to be(true)
    expect(context.errors).to have(2).items
  end

  it "should serialize errors" do

    h = {
      foo: 'bar',
      bar: {
        qux: nil
      },
      baz: [
        { a: 'b' },
        { a: 'c' },
        { a: nil },
        { a: '  ' },
        {}
      ],
      qux: ''
    }

    validations = Errapi::ObjectValidator.new do

      validates :foo, presence: true
      validates :qux, presence: true
      validates_each :baz, :a, presence: true

      validates :bar do
        validates :baz, presence: true
      end

      validates :bar, as: 'corge' do
        validates :qux, presence: true, as: 'grault'
      end
    end

    validations.validate h, context, location_type: :dotted

    expect(context.serialize).to eq({
      errors: [
        {
          reason: :empty,
          message: "This value cannot be empty.",
          location: 'qux',
          location_type: :dotted
        },
        {
          reason: :null,
          message: "This value cannot be null.",
          location: 'baz.2.a',
          location_type: :dotted
        },
        {
          reason: :blank,
          message: "This value cannot be blank.",
          location: 'baz.3.a',
          location_type: :dotted
        },
        {
          reason: :missing,
          message: "This value is required.",
          location: 'baz.4.a',
          location_type: :dotted
        },
        {
          reason: :missing,
          message: "This value is required.",
          location: 'bar.baz',
          location_type: :dotted
        },
        {
          reason: :null,
          message: "This value cannot be null.",
          location: 'corge.grault',
          location_type: :dotted
        }
      ]
    })
  end
end
