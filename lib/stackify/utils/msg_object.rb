module Stackify
  class MsgObject
    def initialize level, msg, caller_str, trans_id=nil, log_uuid=nil, ex=nil
      @level, @msg, @caller_str, @ex = level, msg, caller_str, ex, @trans_id = trans_id,
      @log_uuid = log_uuid
    end

    def to_h
      {
        'id' => @log_uuid,
        'Msg' => @msg.to_s,
        'data' => nil,
        'Ex' => @ex.try(:to_h),
        'Level' => @level.to_s.upcase!,
        #'Tags' => %w(ruby rails),
        'EpochMs' => Time.now.to_f * 1000,
        'Th' => Thread.current.object_id.to_s,
        'TransID' => @trans_id,
        'SrcMethod' => Stackify::Backtrace.method_name(@caller_str),
        'SrcLine' => Stackify::Backtrace.line_number(@caller_str)
      }
    end
  end
end
