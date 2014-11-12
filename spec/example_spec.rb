require 'helper'

RSpec.describe 'errapi' do

  let(:config){ Errapi::Configuration.new }
  let(:context){ Errapi::ValidationContext.new config }

  before :each do
    config.plugin_factory Errapi::Plugins::Message
    config.plugin_factory Errapi::Plugins::Code
  end

  it "should collect and find errors" do

    context.add message: 'foo'
    context.add message: 'bar', code: 'auth.failed'
    context.add message: 'baz', code: 'json.invalid'

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
end
