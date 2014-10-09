require 'helper'

RSpec.describe Errapi::ValidationError do
  let(:options){ {} }
  subject{ described_class.new 'foo', options }

  it "should have a message" do
    expect_error message: 'foo'
  end

  describe "with options" do
    let(:options){ { code: 100, type: 'json', location: '/pointer' } }

    it "should have a code, type and location" do
      expect_error options.merge(message: 'foo')
    end
  end

  def expect_error options = {}
    [ :message, :code, :type, :location ].each do |attr|
      expect(subject.send(attr)).to eq(options.key?(attr) ? options[attr] : nil)
    end
  end
end
