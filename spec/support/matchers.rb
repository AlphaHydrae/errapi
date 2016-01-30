RSpec::Matchers.define :have_errors do |expected|
  match do |actual|
    @expected_errors = expected
    actual_errors = actual.errors
    matching_errors = []

    @expected_errors.each do |expected_error|
      actual_errors.each do |actual_error|
        error = actual_error.to_h
        if error.keys.sort == expected_error.keys.sort && expected_error.keys.all?{ |k| expected_error[k] == error[k] }
          matching_errors << expected_error
          actual_errors.delete_at actual_errors.find_index(actual_error)
          break
        end
      end
    end

    @missing_errors = @expected_errors - matching_errors

    @extra_errors = actual_errors

    @missing_errors.empty? && @extra_errors.empty?
  end

  failure_message do |actual|
    [].tap do |msg|

      msg << "expected that the validation context would contain the following errors:"
      @expected_errors.each do |error|
        msg << "  #{error.inspect}"
      end

      if @missing_errors.any?
        msg << ""
        msg << "the following errors were not found:"
        @missing_errors.each do |error|
          msg << "  #{error.inspect}"
        end
      end

      if @extra_errors.any?
        msg << ""
        msg << "the following extra errors were found:"
        @extra_errors.each do |error|
          msg << "  #{error.to_h.inspect}"
        end
      end

    end.join "\n"
  end
end
