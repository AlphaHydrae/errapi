require 'helper'

RSpec.describe Errapi::Validations::Trim do
  let(:context){ double add_error: nil }

  it "should not accept a string with whitespace at the beginning" do
    [ " abc", "     def", "\tghi", "\n\n\n \tjkl" ].each.with_index do |value,i|
      validate value
      expect(context).to have_received(:add_error).with(reason: :untrimmed).exactly(i + 1).times
    end
  end

  it "should not accept a string with whitespace at the end" do
    [ "mno ", "pqr     ", "stu\t", "vwx\n\n\n \t" ].each.with_index do |value,i|
      validate value
      expect(context).to have_received(:add_error).with(reason: :untrimmed).exactly(i + 1).times
    end
  end

  it "should accept a string with whitespace in the middle" do
    [ "a b", "c d e", "f\t g\n\t\nh \ti" ].each do |value|
      validate value
      expect(context).not_to have_received(:add_error)
    end
  end

  it "should accept a string with no whitespace" do
    validate "abc"
    expect(context).not_to have_received(:add_error)
  end

  it "should accept a value that is not a string" do
    [ nil, true, false, [], {}, 3, 4.5 ].each do |value|
      validate value
      expect(context).not_to have_received(:add_error)
    end
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
