# packs/core/app/public/core/base_service.rb
module Core
  class BaseService
    def self.call(*args, **kwargs, &block)
      # 1. Create a service instance
      service_instance = new(*args, **kwargs)
      # 2. Run the logic
      result = service_instance.call
      # 3. This is where the "Standby" code from the controller finally runs
      yield(result) if block_given?
      # 4. Always return the result object regardless
      result
    end

    protected

    def success(data = {})
      Core::ServiceResult.new(successful: true, data: data)
    end

    def failure(errors = [])
      Core::ServiceResult.new(successful: false, errors: errors)
    end
  end
end
