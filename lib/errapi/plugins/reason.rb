module Errapi

  class Plugins::Reason

    def serialize_error error, serialized
      serialized[:reason] = error.reason
    end
  end
end
