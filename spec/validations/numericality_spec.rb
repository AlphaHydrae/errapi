require 'helper'

RSpec.describe Errapi::Validations::Numericality do
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  let(:sample_numbers){ [ -2000, -999.99, -10, -6.3, -1, -0.24, 0, 0.42, 1, 4.7, 9, 9.9, 10, 10.0001, 20, 1000.01, 2000 ] } # should contain no duplicates
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(ArgumentError, /at least one option/i)
  end

  shared_examples_for "a numerical comparison with one option" do
    let(:runtime_options){ {} }
    let(:error_reason){ "not_#{validation_option}".to_sym }

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

  shared_examples_for "a numerical comparison with two options" do
    let(:runtime_options){ {} }
    let(:lower_bound_error_reason){ "not_#{lower_bound_option}".to_sym }
    let(:upper_bound_error_reason){ "not_#{upper_bound_option}".to_sym }

    shared_examples_for "the comparison" do
      let(:effective_constraints){ { lower_bound_option => lower_bound, upper_bound_option => upper_bound } }

      it "should not accept numbers below the lower bound" do
        numbers_below_lower_bound.each do |n|
          validate n, runtime_options
          expect(context).to have_received(:add_error).with(reason: lower_bound_error_reason, check_value: lower_bound, checked_value: n, constraints: effective_constraints)
        end
      end

      it "should not accept numbers above the upper bound" do
        numbers_above_upper_bound.each do |n|
          validate n, runtime_options
          expect(context).to have_received(:add_error).with(reason: upper_bound_error_reason, check_value: upper_bound, checked_value: n, constraints: effective_constraints)
        end
      end

      it "should accept numbers within the bounds" do
        valid_numbers.each do |n|
          validate n, runtime_options
          expect(context).not_to have_received(:add_error)
        end
      end
    end

    describe "as a number" do
      let(:validation_options){ { lower_bound_option => lower_bound, upper_bound_option => upper_bound } }
      it_should_behave_like "the comparison"
    end

    describe "as a callable" do
      let(:validation_options){ { lower_bound_option => ->(source){ source.foo }, upper_bound_option => ->(source){ source.bar } } }
      let(:runtime_options){ { source: OpenStruct.new(foo: lower_bound, bar: upper_bound) } }
      it_should_behave_like "the comparison"
    end

    describe "as a symbol" do
      let(:validation_options){ { lower_bound_option => :foo, upper_bound_option => :bar } }
      let(:runtime_options){ { source: OpenStruct.new(foo: lower_bound, bar: upper_bound) } }
      it_should_behave_like "the comparison"
    end
  end

  describe "with the :greater_than option" do
    let(:validation_option){ :greater_than }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ sample_numbers.select{ |n| n <= 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n > 10 } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :greater_than_or_equal_to option" do
    let(:validation_option){ :greater_than_or_equal_to }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ sample_numbers.select{ |n| n < 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n >= 10 } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :less_than option" do
    let(:validation_option){ :less_than }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ sample_numbers.select{ |n| n >= 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n < 10 } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :less_than_or_equal_to option" do
    let(:validation_option){ :less_than_or_equal_to }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ sample_numbers.select{ |n| n > 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n <= 10 } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :equal_to option" do
    let(:validation_option){ :equal_to }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ sample_numbers.select{ |n| n != 10 } }
    let(:valid_numbers){ [ 10 ] }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :other_than option" do
    let(:validation_option){ :other_than }
    let(:validation_option_value){ 10 }
    let(:invalid_numbers){ [ 10 ] }
    let(:valid_numbers){ sample_numbers.select{ |n| n != 10 } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :odd option" do
    let(:validation_option){ :odd }
    let(:validation_option_value){ true }
    let(:invalid_numbers){ sample_numbers.select{ |n| n.integer? && n.even? } }
    let(:valid_numbers){ sample_numbers.select{ |n| n.integer? && n.odd? } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :even option" do
    let(:validation_option){ :even }
    let(:validation_option_value){ true }
    let(:invalid_numbers){ sample_numbers.select{ |n| n.integer? && n.odd? } }
    let(:valid_numbers){ sample_numbers.select{ |n| n.integer? && n.even? } }
    it_should_behave_like "a numerical comparison with one option"
  end

  describe "with the :less_than and :greater_than options" do
    let(:lower_bound_option){ :greater_than }
    let(:lower_bound){ -6.3 }
    let(:upper_bound_option){ :less_than }
    let(:upper_bound){ 10 }
    let(:numbers_below_lower_bound){ sample_numbers.select{ |n| n <= -6.3 } }
    let(:numbers_above_upper_bound){ sample_numbers.select{ |n| n >= 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n > -6.3 && n < 10 } }
    it_should_behave_like "a numerical comparison with two options"
  end

  describe "with the :less_than_or_equal_to and :greater_than options" do
    let(:lower_bound_option){ :greater_than }
    let(:lower_bound){ -6.3 }
    let(:upper_bound_option){ :less_than_or_equal_to }
    let(:upper_bound){ 10 }
    let(:numbers_below_lower_bound){ sample_numbers.select{ |n| n <= -6.3 } }
    let(:numbers_above_upper_bound){ sample_numbers.select{ |n| n > 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n > -6.3 && n <= 10 } }
    it_should_behave_like "a numerical comparison with two options"
  end

  describe "with the :less_than and :greater_than_or_equal_to options" do
    let(:lower_bound_option){ :greater_than_or_equal_to }
    let(:lower_bound){ -6.3 }
    let(:upper_bound_option){ :less_than }
    let(:upper_bound){ 10 }
    let(:numbers_below_lower_bound){ sample_numbers.select{ |n| n < -6.3 } }
    let(:numbers_above_upper_bound){ sample_numbers.select{ |n| n >= 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n >= -6.3 && n < 10 } }
    it_should_behave_like "a numerical comparison with two options"
  end

  describe "with the :less_than_or_equal_to and :greater_than_or_equal_to options" do
    let(:lower_bound_option){ :greater_than_or_equal_to }
    let(:lower_bound){ -6.3 }
    let(:upper_bound_option){ :less_than_or_equal_to }
    let(:upper_bound){ 10 }
    let(:numbers_below_lower_bound){ sample_numbers.select{ |n| n < -6.3 } }
    let(:numbers_above_upper_bound){ sample_numbers.select{ |n| n > 10 } }
    let(:valid_numbers){ sample_numbers.select{ |n| n >= -6.3 && n <= 10 } }
    it_should_behave_like "a numerical comparison with two options"
  end

  describe "with the :only_integer option" do
    shared_examples_for "an integer check" do
      let(:runtime_options){ {} }

      shared_examples_for "the check" do
        it "should not accept non-integers" do
          invalid_numbers.each.with_index do |n,i|
            validate n, runtime_options
            expect(context).to have_received(:add_error).with(reason: :not_an_integer, constraints: { only_integer: check_value }).exactly(i + 1).times
          end
        end

        it "should accept integers" do
          valid_numbers.each do |n|
            validate n, runtime_options
            expect(context).not_to have_received(:add_error)
          end
        end
      end

      describe "as a boolean" do
        let(:validation_options){ { only_integer: check_value } }
        it_should_behave_like "the check"
      end

      describe "as a callable" do
        let(:validation_options){ { only_integer: ->(source){ source.foo } } }
        let(:runtime_options){ { source: OpenStruct.new(foo: check_value) } }
        it_should_behave_like "the check"
      end

      describe "as a symbol" do
        let(:validation_options){ { only_integer: :bar } }
        let(:runtime_options){ { source: OpenStruct.new(bar: check_value) } }
        it_should_behave_like "the check"
      end
    end

    describe "set to true" do
      let(:check_value){ true }
      let(:invalid_numbers){ sample_numbers.reject &:integer? }
      let(:valid_numbers){ sample_numbers.select &:integer? }
      it_should_behave_like "an integer check"
    end

    describe "set to false" do
      let(:check_value){ false }
      let(:invalid_numbers){ [] }
      let(:valid_numbers){ sample_numbers }
      it_should_behave_like "an integer check"
    end
  end

  # TODO: check that integer check is not performed if only_integer is false
  # TODO: check that other checks are not performed if only_integer fails

  def validate value, options = {}
    subject.validate value, context, options
  end
end
