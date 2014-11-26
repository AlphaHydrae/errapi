require 'helper'

RSpec.describe 'errapi' do

  let(:state){ Errapi::ValidationState.new }
  let(:context){ Errapi::ValidationContext.new state }

  it "should collect and find errors" do

    state.add_error message: 'foo'
    state.add_error message: 'bar', code: 'auth.failed'
    state.add_error{ |err| err.set message: 'baz', code: 'json.invalid' }

    %w(foo bar baz).each do |message|
      expect(state.error?(message: message)).to be(true)
    end

    [ /fo/, /ba/ ].each do |regexp|
      expect(state.error?(message: regexp)).to be(true)
    end

    expect(state.error?(message: 'qux')).to be(false)
    expect(state.error?(message: /qux/)).to be(false)

    %w(auth.failed json.invalid).each do |code|
      expect(state.error?(code: code)).to be(true)
    end

    [ /^auth\./, /invalid/ ].each do |regexp|
      expect(state.error?(code: regexp)).to be(true)
    end

    expect(state.error?(code: 'broken')).to be(false)
    expect(state.error?(code: /broke/)).to be(false)
  end

  it "should provide a model extension to validate objects" do

    klass = Class.new do
      include Errapi::Model

      attr_accessor :name

      errapi do
        validates :name, presence: true
      end
    end

    o = klass.new
    o.validate context
    expect(state.error?).to be(true)
    expect(state.error?(message: /cannot be null or empty/)).to be(true)
    expect(state.errors).to have(1).item

    state.clear
    o.name = 'foo'
    o.validate context
    expect(state.error?).to be(false)
  end

  it "should validate parsed JSON" do

    h = {
      foo: 'bar',
      bar: {},
      baz: [
        { a: 'b' },
        { a: 'c' },
        { a: nil }
      ]
    }

    bar_validations = Errapi::Validations.new do
      validates :foo, presence: true
    end

    validations = Errapi::Validations.new do

      validates :foo, presence: true
      validates :bar, with: bar_validations
      validates :qux, presence: true
      validates_each :baz, :a, presence: true

      validates :bar do
        validates :baz, presence: true
      end
    end

    validations.validate h, context

    expect(state.error?).to be(true)
    expect(state.error?(message: /cannot be null or empty/)).to be(true)
    expect(state.errors).to have(4).items
    expect(state.error?(location: 'bar.foo')).to be(true)
    expect(state.error?(location: 'qux')).to be(true)
    expect(state.error?(location: 'baz.2.a')).to be(true)
    expect(state.error?(location: 'bar.baz')).to be(true)
  end
end
