module Stackify
  class AuthWorker < Worker

    def initialize name = 'Authorisation worker'
      super
      @type = :auth
    end

    def after_perform result
      if result.try(:status) == 200
        Stackify.send :authorized!
        Stackify.successfull_authorisation result
      else
        Stackify.unsuccessfull_authorisation result, self
      end
    end
  end
end
