require 'helper'

RSpec.describe Errapi::ValidationContext do

  it "should have an empty array of errors" do
    expect(subject.errors).to eq([])
  end

  it "should indicate that there are no errors" do
    expect(subject.error?).to be(false)
  end

  describe "with errors" do
    before :each do
      subject.add 'foo'
      subject.add 'bar'
      subject.add 'baz'
    end

    it "should match an error by message" do
      expect(subject.error?(message: 'foo')).to be(true)
      expect(subject.error?(message: 'bar')).to be(true)
      expect(subject.error?(message: 'baz')).to be(true)
      expect(subject.error?(message: 'qux')).to be(false)
    end

    it "should match an error by message with a regexp" do
      expect(subject.error?(message: /foo/)).to be(true)
      expect(subject.error?(message: /ba/)).to be(true)
      expect(subject.error?(message: /q/)).to be(false)
    end
  end
end
