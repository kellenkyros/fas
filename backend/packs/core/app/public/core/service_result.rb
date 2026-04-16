# packs/core/app/public/core/service_result.rb
module Core
  class ServiceResult < Struct.new(:successful, :data, :errors, keyword_init: true)
    def initialize(successful:, data: nil, errors: [])
      super(successful: successful, data: data || {}, errors: Array(errors))
    end

    # This allows: if result.success?
    def success?
      !!successful
    end

    # This allows: result.success { |data| ... }
    def on_success(&block)
      yield(data) if success? && block_given?
    end

    # This allows: result.failure { |errors| ... }
    def on_failure(&block)
      yield(errors) if !success? && block_given?
    end

    def payload
      if success?
        { data: data }
      else
        { errors: errors }
      end
    end
  end
end
