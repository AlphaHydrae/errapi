require 'helper'

RSpec.describe Errapi::Validations::Format do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(ArgumentError, /either :with or :without/i)
  end

  it "should not allow multiple options to be set" do
    expect{ described_class.new with: /abc/, without: /def/ }.to raise_error(ArgumentError, /either :with or :without/i)
  end

  it "should not accept an invalid format" do
    [ nil, true, 4, [] ].each do |invalid_format|
      %i(with without).each do |option|
        expect{ described_class.new({ option => invalid_format }) }.to raise_error(ArgumentError, /must be a regular expression/i)
      end
    end
  end

  describe "with a callable returning an invalid format" do
    let(:validation_options){ { with: Proc.new{ 'foo' } } }

    it "should raise an error when validating" do
      expect{ validate 'bar' }.to raise_error(ArgumentError, /must return a regular expression/i)
    end
  end

  describe "with a symbol returning an invalid format" do
    let(:validation_options){ { with: :pattern } }

    it "should raise an error when validating" do
      expect{ validate 'bar', source: OpenStruct.new(pattern: 'foo') }.to raise_error(ArgumentError, /must return a regular expression/i)
    end
  end

  describe "with the :with option" do
    let(:runtime_options){ {} }

    shared_examples_for "a positive pattern match" do
      it "should not accept a value that doesn't match the pattern" do
        [ ' ', 'abd', 'efh', :ijk, [] ].each.with_index do |value,i|
          validate value, runtime_options
          expect(context).to have_received(:add_error).with(reason: :invalid_format, check_value: /abc/).exactly(i + 1).times
        end
      end

      it " should accept a value that matches the pattern" do
        [ 'abc', 'abcdef', 'ghiabcjkl', Class.new{ def to_s; 'abc'; end }.new ].each do |value|
          validate value, runtime_options
          expect(context).not_to have_received(:add_error)
        end
      end
    end

    describe "as a regexp" do
      let(:validation_options){ { with: /abc/ } }
      it_should_behave_like "a positive pattern match"
    end

    describe "as a callable" do
      let(:validation_options){ { with: ->(source){ source.pattern } } }
      let(:runtime_options){ { source: OpenStruct.new(pattern: /abc/) } }
      it_should_behave_like "a positive pattern match"
    end

    describe "as a symbol" do
      let(:validation_options){ { with: :pattern } }
      let(:runtime_options){ { source: OpenStruct.new(pattern: /abc/) } }
      it_should_behave_like "a positive pattern match"
    end
  end

  describe "with the :without option" do
    let(:runtime_options){ {} }

    shared_examples_for "a negative pattern match" do
      let(:validation_options){ { without: /abc/ } }

      it "should accept a value that doesn't match the pattern" do
        [ ' ', 'abd', 'efh', :ijk, [] ].each do |value|
          validate value
          expect(context).not_to have_received(:add_error)
        end
      end

      it " should not accept a value that matches the pattern" do
        [ 'abc', 'abcdef', 'ghiabcjkl', Class.new{ def to_s; 'abc'; end }.new ].each.with_index do |value,i|
          validate value
          expect(context).to have_received(:add_error).with(reason: :invalid_format, check_value: /abc/).exactly(i + 1).times
        end
      end
    end

    describe "as a regexp" do
      let(:validation_options){ { without: /abc/ } }
      it_should_behave_like "a negative pattern match"
    end

    describe "as a callable" do
      let(:validation_options){ { without: ->(source){ source.pattern } } }
      let(:runtime_options){ { source: OpenStruct.new(pattern: /abc/) } }
      it_should_behave_like "a negative pattern match"
    end

    describe "as a symbol" do
      let(:validation_options){ { without: :pattern } }
      let(:runtime_options){ { source: OpenStruct.new(pattern: /abc/) } }
      it_should_behave_like "a negative pattern match"
    end
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
