require 'helper'

RSpec.describe 'errapi' do

  let(:config){ Errapi::Configuration.new }
  let(:context){ Errapi::ValidationContext.new config }

  before :each do
    config.plugin Errapi::Plugins::Message
  end

  it "should collect and find errors" do

    context.add message: 'foo'
    context.add message: 'bar'
    context.add message: 'baz'

    %w(foo bar baz).each{ |message| expect(context.error?(message: message)).to be(true) }
    expect(context.error?(message: /ba/)).to be(true)
  end
end
