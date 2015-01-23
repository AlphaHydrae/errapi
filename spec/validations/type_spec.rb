require 'helper'

RSpec.describe Errapi::Validations::Type do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  let(:type){ Array }
  let(:subtype){ Class.new type }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(ArgumentError, /only one/i)
  end

  it "should not allow two options to be set" do
    %i(instance_of kind_of is_a is_an instance_of is_a is_an kind_of).each_slice(2).with_index do |slice,i|
      expect{ described_class.new slice.inject({}){ |memo,option| memo[option] = type; memo } }.to raise_error(ArgumentError, /only one/i)
    end
  end

  it "should not allow something other than a class or module to be given as an option" do
    [ nil, true, 'abc', [] ].each do |bad_type|
      %i(instance_of kind_of is_a is_an).each do |option|
        expect{ described_class.new({ option => bad_type }) }.to raise_error(ArgumentError, /class or module/i)
      end
    end
  end

  describe "with the :instance_of option" do
    let(:validation_options){ { instance_of: type } }

    it "should not accept another type" do

      [ nil, true, 'abc', {} ].each.with_index do |value,i|
        validate value
        expect(context).to have_received(:add_error).with(reason: :wrong_type, check_value: type, checked_value: value.class)
      end

      expect(context).to have_received(:add_error).exactly(4).times
    end

    it "should not accept a subtype" do
      validate subtype.new
      expect(context).to have_received(:add_error)
    end

    it "should accept the type" do
      validate type.new
      expect(context).not_to have_received(:add_error)
    end
  end

  shared_examples_for "a comparison that allows subtypes" do

    it "should not accept another type" do

      [ nil, true, 'abc', {} ].each.with_index do |value,i|
        validate value
        expect(context).to have_received(:add_error).with(reason: :wrong_type, check_value: type, checked_value: value.class)
      end

      expect(context).to have_received(:add_error).exactly(4).times
    end

    it "should accept a subtype" do
      validate subtype.new
      expect(context).not_to have_received(:add_error)
    end

    it "should accept the type" do
      validate type.new
      expect(context).not_to have_received(:add_error)
    end
  end

  %i(kind_of is_a is_an).each do |option|
    describe "with the #{option} option" do
      let(:validation_options){ { option => type } }
      it_should_behave_like "a comparison that allows subtypes"
    end
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
