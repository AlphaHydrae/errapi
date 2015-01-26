require 'helper'

RSpec.describe Errapi::Validations::Length do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(/options must be supplied/i)
  end

  it "should not accept combining the :is option with other options" do
    { minimum: 0, maximum: 20, within: 0..20 }.each_pair do |k,v|
      expect{ described_class.new({ k => v, :is => 10}) }.to raise_error(/cannot be combined/i)
    end
  end

  it "should not accept combining the :minimum/:maximum and :within options" do
    %i(minimum maximum).each do |option|
      expect{ described_class.new({ option => 10, :within => 0..20 }) }.to raise_error(/cannot be combined/i)
    end
  end

  it "should require a numeric value for the :is, :minimum or :maximum options" do
    %i(is minimum maximum).each do |option|
      [ nil, true, false, [], {}, Time.now ].each do |invalid|
        expect{ described_class.new({ option => invalid }) }.to raise_error(/must be a numeric value/i)
      end
    end
  end

  it "should require a numeric range for the :within option" do
    [ nil, true, false, [], {}, Time.now, Range.new(Time.now - 2000, Time.now + 2000) ].each do |invalid|
      expect{ described_class.new(within: invalid) }.to raise_error(/must be a numeric range/i)
    end
  end

  shared_examples_for "a length validation" do
    it "should accept an object that doesn't have a length" do
      validate Object.new
      expect(context).not_to have_received(:add_error)
    end
  end

  describe "with the :is option" do
    let(:validation_options){ { is: 10 } }
    it_should_behave_like "a length validation"

    it "should not accept a length other than the supplied one" do
      [ -2000, -1, 0, 1, 9, 11, 2000 ].each do |invalid_length|
        validate OpenStruct.new(length: invalid_length)
        expect(context).to have_received(:add_error).with(reason: :wrong_length, check_value: 10, checked_value: invalid_length, constraints: { is: 10 })
      end
    end

    it "should accept the correct length" do
      validate OpenStruct.new(length: 10)
      expect(context).not_to have_received(:add_error)
    end
  end

  describe "with the :minimum option" do
    let(:validation_options){ { minimum: 10 } }
    it_should_behave_like "a length validation"

    it "should not accept a length smaller than the supplied one" do
      [ -2000, -1, 0, 1, 9 ].each do |invalid_length|
        validate OpenStruct.new(length: invalid_length)
        expect(context).to have_received(:add_error).with(reason: :too_short, check_value: 10, checked_value: invalid_length, constraints: { minimum: 10 })
      end
    end

    it "should accept a length greater than or equal to the supplied one" do
      [ 10, 11, 2000 ].each do |valid_length|
        validate OpenStruct.new(length: valid_length)
        expect(context).not_to have_received(:add_error)
      end
    end
  end

  describe "with the :maximum option" do
    let(:validation_options){ { maximum: 10 } }
    it_should_behave_like "a length validation"

    it "should not accept a length greater than the supplied one" do
      [ 11, 2000 ].each do |invalid_length|
        validate OpenStruct.new(length: invalid_length)
        expect(context).to have_received(:add_error).with(reason: :too_long, check_value: 10, checked_value: invalid_length, constraints: { maximum: 10 })
      end
    end

    it "should accept a length smaller than or equal to the supplied one" do
      [ -2000, -1, 0, 1, 9, 10 ].each do |valid_length|
        validate OpenStruct.new(length: valid_length)
        expect(context).not_to have_received(:add_error)
      end
    end
  end

  describe "with both the :minimum and :maximum options" do
    let(:validation_options){ { minimum: 10, maximum: 20 } }
    it_should_behave_like "a length validation"

    it "should not accept a length that is out of bounds" do
      [ -2000, -1, 0, 1, 9, 21, 30, 2000 ].each do |invalid_length|
        validate OpenStruct.new(length: invalid_length)
        if invalid_length < 10
          expect(context).to have_received(:add_error).with(reason: :too_short, check_value: 10, checked_value: invalid_length, constraints: { minimum: 10, maximum: 20 })
        else
          expect(context).to have_received(:add_error).with(reason: :too_long, check_value: 20, checked_value: invalid_length, constraints: { minimum: 10, maximum: 20 })
        end
      end
    end

    it "should accept a length that is within bounds" do
      (10..20).each do |valid_length|
        validate OpenStruct.new(length: valid_length)
        expect(context).not_to have_received(:add_error)
      end
    end
  end

  describe "with the :within option" do
    let(:validation_options){ { within: 10..20 } }
    it_should_behave_like "a length validation"

    it "should not accept a length that is out of bounds" do
      [ -2000, -1, 0, 1, 9, 21, 30, 2000 ].each do |invalid_length|
        validate OpenStruct.new(length: invalid_length)
        if invalid_length < 10
          expect(context).to have_received(:add_error).with(reason: :too_short, check_value: 10, checked_value: invalid_length, constraints: { minimum: 10, maximum: 20 })
        else
          expect(context).to have_received(:add_error).with(reason: :too_long, check_value: 20, checked_value: invalid_length, constraints: { minimum: 10, maximum: 20 })
        end
      end
    end

    it "should accept a length that is within bounds" do
      (10..20).each do |valid_length|
        validate OpenStruct.new(length: valid_length)
        expect(context).not_to have_received(:add_error)
      end
    end
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
