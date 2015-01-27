require 'helper'

RSpec.describe Errapi::Validations::Presence do

  let(:context){ double add_error: nil }

  it "should not accept a missing value" do
    [ nil, '', ' ', 'abc' ].each.with_index do |value,i|
      validate value, value_set: false
      expect(context).to have_received(:add_error).with(reason: :missing).exactly(i + 1).times
    end
  end

  it "should not accept a null value" do
    validate nil
    expect(context).to have_received(:add_error).with(reason: :null)
  end

  { string: '', array: [], hash: {}, symbol: :'', queue: Queue.new }.each_pair do |type,value|
    it "should not accept an empty #{type}" do
      validate value
      expect(context).to have_received(:add_error).with(reason: :empty)
    end
  end

  it "should not accept a blank string" do
    [ " ", "\t", "\n", "\t \n" ].each.with_index do |value,i|
      validate value
      expect(context).to have_received(:add_error).with(reason: :blank).exactly(i + 1).times
    end
  end

  it "should not accept an object which indicates that it is blank" do
    validate Class.new{ def blank?; true; end }.new
    expect(context).to have_received(:add_error).with(reason: :blank)
  end

  it "should accept other values" do
    [ true, 'abc', :sym, [ nil ], { foo: 'bar' } ].each do |value|
      validate value
      expect(context).not_to have_received(:add_error)
    end
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
