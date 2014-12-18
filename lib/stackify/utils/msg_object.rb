module Stackify
  class MsgObject
    def initialize level, msg, caller_str, ex=nil
      @level, @msg, @caller_str, @ex = level, msg, caller_str, ex
    end

    def to_h
      {
        'Msg' => @msg.to_s,
        'data' => nil,
        'Ex' => @ex.try(:to_h),
        'Level' => @level.to_s.upcase!,
        #'Tags' => %w(ruby rails),
        'EpochMs' => Time.now.to_f * 1000,
        'Th' => Thread.current.object_id.to_s,
        'TransID' => Stackify::EnvDetails.instance.request_details.try{ |d| d['uuid'] },
        'SrcMethod' => Stackify::Backtrace.method_name(@caller_str),
        'SrcLine' => Stackify::Backtrace.line_number(@caller_str)
      }
    end
  end
end
