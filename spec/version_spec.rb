require 'helper'

RSpec.describe 'Version' do

  it "should be correct" do
    expect(Errapi::VERSION).to eq(File.read(File.join(File.dirname(__FILE__), '../VERSION')))
  end
end
