require 'helper'

RSpec.describe Errapi::Validations::Numericality do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(ArgumentError, /at least one option/i)
  end

  shared_examples_for "a numerical comparison with one option" do
    let(:runtime_options){ {} }

    shared_examples_for "the comparison" do
      it "should not accept numbers that do not match the option" do
        invalid_numbers.each do |n|
          validate n, runtime_options
          expect(context).to have_received(:add_error).with(reason: error_reason, check_value: validation_option_value, checked_value: n, constraints: { validation_option => validation_option_value })
        end
      end

      it "should accept numbers that match the option" do
        valid_numbers.each do |n|
          validate n, runtime_options
          expect(context).not_to have_received(:add_error)
        end
      end
    end

    describe "as a number" do
      let(:validation_options){ { validation_option => validation_option_value } }
      it_should_behave_like "the comparison"
    end

    describe "as a callable" do
      let(:validation_options){ { validation_option => ->(source){ source.bound } } }
      let(:runtime_options){ { source: OpenStruct.new(bound: validation_option_value) } }
      it_should_behave_like "the comparison"
    end

    describe "as a symbol" do
      let(:validation_options){ { validation_option => :bound } }
      let(:runtime_options){ { source: OpenStruct.new(bound: validation_option_value) } }
      it_should_behave_like "the comparison"
    end
  end

  describe "with the :greater_than option" do
    let(:validation_option){ :greater_than }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ -2000, -10, -1, 0, 1, 9, 10 ] }
    let(:valid_numbers){ [ 11, 20, 2000 ] }
    let(:error_reason){ :not_greater_than }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :greater_than_or_equal_to option" do
    let(:validation_option){ :greater_than_or_equal_to }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ -2000, -10, -1, 0, 1, 9 ] }
    let(:valid_numbers){ [ 10, 11, 20, 2000 ] }
    let(:error_reason){ :not_greater_than_or_equal_to }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :less_than option" do
    let(:validation_option){ :less_than }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ 10, 11, 20, 2000 ] }
    let(:valid_numbers){ [ -2000, -10, -1, 0, 1, 9 ] }
    let(:error_reason){ :not_less_than }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :less_than_or_equal_to option" do
    let(:validation_option){ :less_than_or_equal_to }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ 11, 20, 2000 ] }
    let(:valid_numbers){ [ -2000, -10, -1, 0, 1, 9, 10 ] }
    let(:error_reason){ :not_less_than_or_equal_to }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :equal_to option" do
    let(:validation_option){ :equal_to }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ -2000, -10, -1, 0, 1, 9, 11, 20, 2000 ] }
    let(:valid_numbers){ [ 10 ] }
    let(:error_reason){ :not_equal_to }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :other_than option" do
    let(:validation_option){ :other_than }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ 10 ] }
    let(:valid_numbers){ [ -2000, -10, -1, 0, 1, 9, 11, 20, 2000 ] }
    let(:error_reason){ :not_other_than }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :odd option" do
    let(:validation_option){ :odd }
    let(:validation_option_value){ true }
    let(:invalid_numbers){ [ -2000, -10, 0, 10, 20, 2000 ] }
    let(:valid_numbers){ [ -1, 1, 9, 11 ] }
    let(:error_reason){ :not_odd }
    it_should_behave_like "a numerical comparison with one option"
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
