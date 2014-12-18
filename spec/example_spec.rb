require 'helper'

RSpec.describe 'errapi' do

  let(:context){ Errapi.config.new_context }

  it "should collect and find errors" do

    context.add_error message: 'foo'
    context.add_error message: 'bar', code: 'auth.failed'
    context.add_error{ |err| err.message = 'baz'; err.code = 'json.invalid' }

    %w(foo bar baz).each do |message|
      expect(context.errors?(message: message)).to be(true)
    end

    [ /fo/, /ba/ ].each do |regexp|
      expect(context.errors?(message: regexp)).to be(true)
    end

    expect(context.errors?(message: 'qux')).to be(false)
    expect(context.errors?(message: /qux/)).to be(false)

    %w(auth.failed json.invalid).each do |code|
      expect(context.errors?(code: code)).to be(true)
    end

    [ /^auth\./, /invalid/ ].each do |regexp|
      expect(context.errors?(code: regexp)).to be(true)
    end

    expect(context.errors?(code: 'broken')).to be(false)
    expect(context.errors?(code: /broke/)).to be(false)
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
        validates Proc.new(&:age), presence: true, with: { location: 'age' }
      end
    end

    o = klass.new
    o.validate context
    expect(context.errors?).to be(true)
    expect(context.errors?(location: 'name')).to be(true)
    expect(context.errors).to have(1).item

    context.clear
    o.name = 'foo'
    o.validate context
    expect(context.errors?).to be(false)

    context.clear
    o.name = nil
    o.validate :with_age, context
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

    bar_validations = Errapi::ObjectValidations.new do
      validates :foo, presence: true
    end

    validations = Errapi::ObjectValidations.new do

      validates :foo, presence: true
      validates :bar, using: bar_validations
      validates :qux, presence: true
      validates_each :baz, :a, presence: true

      validates :bar do
        validates :baz, presence: true
      end

      validates :bar, with: { location: 'corge' } do
        validates :qux, presence: true, with: { relative_location: 'grault' }
      end
    end

    validations.validate h, context

    expect(context.errors?).to be(true)
    expect(context.errors).to have(6).items
    expect(context.errors?(location: 'bar.foo')).to be(true)
    expect(context.errors?(location: 'qux')).to be(true)
    expect(context.errors?(location: 'baz.2.a')).to be(true)
    expect(context.errors?(location: 'baz.4.a')).to be(true)
    expect(context.errors?(location: 'bar.baz')).to be(true)
    expect(context.errors?(location: 'corge.grault')).to be(true)
  end

  it "should conditionally execute validations based on custom conditions" do

    h = {
      foo: 'bar',
      bar: {}
    }

    validations = Errapi::ObjectValidations.new do
      validates :baz, presence: { if: :baz }
      validates :qux, presence: { if: Proc.new{ |h| h[:foo] == 'baz' } }
      validates :corge, presence: { unless: :bar }
      validates :grault, presence: { unless: Proc.new{ |h| h[:foo] == 'bar' } }
      validates :garply, presence: true, if: :baz
      validates if: :baz do
        validates :waldo, presence: true
      end
    end

    validations.validate h, context

    expect(context.errors?).to be(false)
    expect(context.errors).to be_empty

    h = {
      foo: 'baz',
      baz: []
    }

    validations.validate h, context

    expect(context.errors?).to be(true)
    expect(context.errors).to have(6).items
    expect(context.errors?(location: 'baz')).to be(true)
    expect(context.errors?(location: 'qux')).to be(true)
    expect(context.errors?(location: 'corge')).to be(true)
    expect(context.errors?(location: 'grault')).to be(true)
    expect(context.errors?(location: 'garply')).to be(true)
    expect(context.errors?(location: 'waldo')).to be(true)
  end

  it "should conditionally execute validations based on previous errors" do

    h = {
      foo: 'bar',
      bar: false,
      qux: {}
    }

    validations = Errapi::ObjectValidations.new do
      validates :foo, presence: true
      validates :bar, presence: true, if_error: { location: 'foo' }
      validates :baz, presence: { unless_error: { location: 'foo' } }
      validates :qux do
        validates :corge, presence: { unless_error: { location: 'foo' } }
        validates :grault, presence: { if_error: { relative_location: 'corge' } }
      end
    end

    validations.validate h, context

    expect(context.errors?).to be(true)
    expect(context.errors).to have(3).item
    expect(context.errors?(location: 'baz')).to be(true)
    expect(context.errors?(location: 'qux.corge')).to be(true)
    expect(context.errors?(location: 'qux.grault')).to be(true)

    h = {
      foo: nil,
      qux: {}
    }

    context.clear
    validations.validate h, context

    expect(context.errors?).to be(true)
    expect(context.errors).to have(2).items
    expect(context.errors?(location: 'foo')).to be(true)
    expect(context.errors?(location: 'bar')).to be(true)
  end
end
