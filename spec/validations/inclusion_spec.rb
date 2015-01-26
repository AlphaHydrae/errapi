require 'helper'

RSpec.describe Errapi::Validations::Inclusion do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(/either :in or :within/i)
  end

  it "should not accept an object without the #include? method as an option" do
    %i(in within).each do |option|
      [ nil, true, false, Object.new ].each do |invalid_option|
        expect{ described_class.new({ option => invalid_option }) }.to raise_error(/an object with the #include\? method/i)
      end
    end
  end

  describe "with a callable returning an invalid list" do
    let(:validation_options){ { in: Proc.new{ :foo } } }

    it "should raise an error when validating" do
      expect{ validate 'foo' }.to raise_error(/must return an object with the #include\? method/i)
    end
  end

  describe "with a symbol returning an invalid list" do
    let(:validation_options){ { in: :allowed_values } }

    it "should raise an error when validating" do
      expect{ validate 'foo', source: OpenStruct.new(allowed_values: :foo) }.to raise_error(/must return an object with the #include\? method/i)
    end
  end

  shared_examples_for "an inclusion validation" do
    let(:runtime_options){ {} }
    let(:validation_options){ { inclusion_option => %w(foo bar baz) } }

    it "should not accept a value not in the supplied list" do
      %w(qux corge grault).each.with_index do |invalid_value,i|
        validate invalid_value, runtime_options
        expect(context).to have_received(:add_error).with(reason: :not_included, check_value: %w(foo bar baz)).exactly(i + 1).times
      end
    end

    it "should accept a value in the supplied list" do
      %w(foo bar baz).each do |valid_value|
        validate valid_value, runtime_options
        expect(context).not_to have_received(:add_error)
      end
    end
  end

  shared_examples_for "a callable inclusion option" do
    describe "as a list" do
      let(:validation_options){ { in: %w(foo bar baz) } }
      it_should_behave_like "an inclusion validation"
    end

    describe "as a callable" do
      let(:validation_options){ { in: ->(source){ source.allowed_values } } }
      let(:runtime_options){ { source: OpenStruct.new(allowed_values: %w(foo bar baz)) } }
      it_should_behave_like "an inclusion validation"
    end

    describe "as a symbol" do
      let(:validation_options){ { in: :allowed_values } }
      let(:runtime_options){ { source: OpenStruct.new(allowed_values: %w(foo bar baz)) } }
      it_should_behave_like "an inclusion validation"
    end
  end

  describe "with the :in option" do
    let(:inclusion_option){ :in }
    it_should_behave_like "a callable inclusion option"
  end

  describe "with the :within option" do
    let(:inclusion_option){ :within }
    it_should_behave_like "a callable inclusion option"
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
