module Stackify
  class AddMsgWorker < Worker

    def initialize name = 'AddMessage worker'
      super
      @type = :add_msg
    end
  end
end
