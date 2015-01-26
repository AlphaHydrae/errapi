require 'helper'

RSpec.describe Errapi::Validations::Exclusion do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(/either :from or :in or :within/i)
  end

  it "should not accept an object without the #include? method as an option" do
    %i(in within).each do |option|
      [ nil, true, false, Object.new ].each do |invalid_option|
        expect{ described_class.new({ option => invalid_option }) }.to raise_error(/an object with the #include\? method/i)
      end
    end
  end

  describe "with a callable returning an invalid list" do
    let(:validation_options){ { from: Proc.new{ :foo } } }

    it "should raise an error when validating" do
      expect{ validate 'foo' }.to raise_error(/must return an object with the #include\? method/i)
    end
  end

  describe "with a symbol returning an invalid list" do
    let(:validation_options){ { from: :excluded_values } }

    it "should raise an error when validating" do
      expect{ validate 'foo', source: OpenStruct.new(excluded_values: :foo) }.to raise_error(/must return an object with the #include\? method/i)
    end
  end

  shared_examples_for "an exclusion validation" do
    let(:runtime_options){ {} }
    let(:validation_options){ { exclusion_option => %w(foo bar baz) } }

    it "should not accept a value in the supplied list" do
      %w(foo bar baz).each.with_index do |invalid_value,i|
        validate invalid_value, runtime_options
        expect(context).to have_received(:add_error).with(reason: :excluded, check_value: %w(foo bar baz)).exactly(i + 1).times
      end
    end

    it "should accept a value not in the supplied list" do
      %w(qux corge grault).each do |valid_value|
        validate valid_value, runtime_options
        expect(context).not_to have_received(:add_error)
      end
    end
  end

  shared_examples_for "a callable exclusion option" do
    describe "as a list" do
      let(:validation_options){ { from: %w(foo bar baz) } }
      it_should_behave_like "an exclusion validation"
    end

    describe "as a callable" do
      let(:validation_options){ { from: ->(source){ source.excluded_values } } }
      let(:runtime_options){ { source: OpenStruct.new(excluded_values: %w(foo bar baz)) } }
      it_should_behave_like "an exclusion validation"
    end

    describe "as a symbol" do
      let(:validation_options){ { from: :excluded_values } }
      let(:runtime_options){ { source: OpenStruct.new(excluded_values: %w(foo bar baz)) } }
      it_should_behave_like "an exclusion validation"
    end
  end

  describe "with the :from option" do
    let(:exclusion_option){ :from }
    it_should_behave_like "a callable exclusion option"
  end

  describe "with the :in option" do
    let(:exclusion_option){ :in }
    it_should_behave_like "a callable exclusion option"
  end

  describe "with the :within option" do
    let(:exclusion_option){ :within }
    it_should_behave_like "a callable exclusion option"
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
