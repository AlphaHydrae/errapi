require 'helper'

RSpec.describe Errapi::Validations::Type do
  SPEC_TYPE_VALIDATION_OPTIONS = %i(instance_of kind_of is_a is_an)
  SPEC_TYPE_VALIDATION_ALIASES = %i(string number integer boolean object array)
  let(:context){ double add_error: nil }
  let(:validation_options){ {} }
  let(:type){ Array }
  let(:subtype){ Class.new type }
  subject{ described_class.new validation_options }

  it "should require at least one option to be set" do
    expect{ described_class.new }.to raise_error(ArgumentError, /only one/i)
  end

  it "should not allow two options to be set" do
    SPEC_TYPE_VALIDATION_OPTIONS.permutation(2).to_a.collect(&:sort).uniq.each do |slice|
      expect{ described_class.new slice.inject({}){ |memo,option| memo[option] = type; memo } }.to raise_error(ArgumentError, /only one/i)
    end
  end

  it "should not accept something other than a class, module or type alias as an option" do
    [ nil, true, 'abc', {} ].each do |bad_type|
      %i(instance_of kind_of is_a is_an).each do |option|
        expect{ described_class.new({ option => bad_type }) }.to raise_error(ArgumentError, /class or module/i)
      end
    end
  end

  it "should not accept an empty array as an option" do
    %i(instance_of kind_of is_a is_an).each do |option|
      expect{ described_class.new({ option => [] }) }.to raise_error(ArgumentError, /at least one class or module is required/i)
    end
  end

  it "should not accept a type alias for the :instance_of option" do
    SPEC_TYPE_VALIDATION_ALIASES.each do |type_alias|
      expect{ described_class.new instance_of: type_alias }.to raise_error(ArgumentError, /type aliases cannot be used/i)
    end
  end

  describe "with the :instance_of option" do
    let(:types_wrapper){ [*types] }
    let(:invalid_values){ [ 2, true, 'abc' ] }
    let(:validation_options){ { instance_of: types } }

    shared_examples_for "an exact type match" do

      it "should not accept another type" do

        invalid_values.each.with_index do |value,i|
          validate value
          expect(context).to have_received(:add_error).with(reason: :wrong_type, check_value: types_wrapper, checked_value: value.class)
        end

        expect(context).to have_received(:add_error).exactly(3).times
      end

      it "should not accept a subtype" do
        types_wrapper.each do |type|
          subtype = Class.new type
          validate subtype.new
          expect(context).to have_received(:add_error).with(reason: :wrong_type, check_value: types_wrapper, checked_value: subtype)
        end
      end

      it "should accept the type" do
        types_wrapper.each do |type|
          validate type.new
          expect(context).not_to have_received(:add_error)
        end
      end
    end

    describe "with one type" do
      let(:types){ Array }
      it_should_behave_like "an exact type match"
    end

    describe "with multiple types" do
      let(:types){ [ Array, Hash ] }
      it_should_behave_like "an exact type match"
    end
  end

  shared_examples_for "a comparison that allows subtypes" do
    let(:types_wrapper){ [*types] }
    let(:invalid_values){ [ 2, true, 'abc' ] }
    let(:validation_options){ { type_option => types } }

    shared_examples_for "a lenient type match" do

      it "should not accept another type" do

        invalid_values.each.with_index do |value,i|
          validate value
          expect(context).to have_received(:add_error).with(reason: :wrong_type, check_value: types_wrapper, checked_value: value.class)
        end

        expect(context).to have_received(:add_error).exactly(3).times
      end

      it "should accept a subtype" do
        types_wrapper.each do |type|
          subtype = Class.new type
          validate subtype.new
          expect(context).not_to have_received(:add_error)
        end
      end

      it "should accept the type" do
        types_wrapper.each do |type|
          validate type.new
          expect(context).not_to have_received(:add_error)
        end
      end
    end

    describe "with one type" do
      let(:types){ Array }
      it_should_behave_like "a lenient type match"
    end

    describe "with multiple types" do
      let(:types){ [ Array, Hash ] }
      it_should_behave_like "a lenient type match"
    end

    describe "with a type alias" do
      let(:types){ :object }
      let(:types_wrapper){ [ Hash ] }
      it_should_behave_like "a lenient type match"
    end

    describe "with a mix" do
      let(:types){ [ :object, Array, Set, :array ] }
      let(:types_wrapper){ [ Hash, Array, Set ] }
      it_should_behave_like "a lenient type match"
    end
  end

  %i(kind_of is_a is_an).each do |option|
    describe "with the #{option} option" do
      let(:type_option){ option }
      it_should_behave_like "a comparison that allows subtypes"
    end
  end

  describe "type aliases" do
    let(:aliases){ %i(string number integer boolean object array null) }
    let(:sample_values){ { string: 'abc', number: 4.5, integer: 3, boolean: false, object: { foo: 'bar' }, array: [ 1, 2, 3 ] } }
    let(:special_cases){ { number: [ :integer ] } } # number is a superset of integer
    let(:corresponding_types){ { string: [ String ], number: [ Numeric ], integer: [ Integer ], boolean: [ TrueClass, FalseClass ], object: [ Hash ], array: [ Array ] } }

    SPEC_TYPE_VALIDATION_ALIASES.each do |type_alias|
      describe type_alias.to_s do
        let(:validation_options){ { kind_of: type_alias } }

        it "should not accept other types" do

          invalid_values = sample_values.reject{ |k,v| k == type_alias }
          invalid_values.reject!{ |k,v| special_cases[type_alias] && special_cases[type_alias].include?(k) }

          invalid_values.each_pair do |type,invalid_value|
            validate invalid_value
            expect(context).to have_received(:add_error).with(reason: :wrong_type, check_value: corresponding_types[type_alias], checked_value: invalid_value.class)
          end
        end

        it "should accept the type" do

          validate sample_values[type_alias]
          expect(context).not_to have_received(:add_error)

          if special_cases[type_alias]
            special_cases[type_alias].each do |special_case|
              validate sample_values[special_case]
              expect(context).not_to have_received(:add_error)
            end
          end
        end
      end
    end
  end

  def validate value, options = {}
    subject.validate value, context, options
  end
end
