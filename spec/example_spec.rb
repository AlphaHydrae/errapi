require 'helper'

RSpec.describe 'errapi' do

  let(:context){ Errapi::ValidationContext.new }

  it "should collect and find errors" do

    context.add_error message: 'foo'
    context.add_error message: 'bar', code: 'auth.failed'
    context.add_error{ |err| err.set message: 'baz', code: 'json.invalid' }

    %w(foo bar baz).each do |message|
      expect(context.error?(message: message)).to be(true)
    end

    [ /fo/, /ba/ ].each do |regexp|
      expect(context.error?(message: regexp)).to be(true)
    end

    expect(context.error?(message: 'qux')).to be(false)
    expect(context.error?(message: /qux/)).to be(false)

    %w(auth.failed json.invalid).each do |code|
      expect(context.error?(code: code)).to be(true)
    end

    [ /^auth\./, /invalid/ ].each do |regexp|
      expect(context.error?(code: regexp)).to be(true)
    end

    expect(context.error?(code: 'broken')).to be(false)
    expect(context.error?(code: /broke/)).to be(false)
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
    expect(context.error?).to be(true)
    expect(context.error?(message: /cannot be null or empty/)).to be(true)

    context.clear
    o.name = 'foo'
    o.validate context
    expect(context.error?).to be(false)
  end
end