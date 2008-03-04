path_to_gui_file = File.expand_path(File.dirname(__FILE__) + '/../.path_to_gui')
PATH_TO_RAILS = if File.exists? path_to_gui_file
  File.read(path_to_gui_file).strip
else
  File.expand_path(File.dirname(__FILE__) + '/../../ey-gui')
end

Adhearsion::Configuration.configure do |config|
  
  config.enable_asterisk
  config.enable_rails :path => PATH_TO_RAILS, :env => :development
  
  ### Should be able to write multiple files!
  ### Should be able to write locally!
  ### Should be able to write remotely
  ### Should be able to write remotely in parallel!
  
  
  # config.asterisk.generate :files => %w[agents queues], :write => :locally
  # config.asterisk.generate :files => %w[agents queues], :write => :remotely
  
  # By default Asterisk is enabled with the default settings
  # config.asterisk.enable_ami :host => "127.0.0.1", :username => "admin", :password => "password"
  
  # config.enable_drb 
  
end

THIS_SERVER = "pbx-1"

# This is basically a translation of ast_channel_reason2str() from main/channel.c and
# ast_control_frame_type in include/asterisk/frame.h in the Asterisk source code.
ASTERISK_FRAME_STATES = [
  :failure,     # "Call Failure (not BUSY, and not NO_ANSWER, maybe Circuit busy or down?)"
  :hangup,      # Other end has hungup
  :ring,        # Local ring
  :ringing,     # Remote end is ringing
  :answer,      # Remote end has answered
  :busy,        # Remote end is busy
  :takeoffhook, # Make it go off hook
  :offhook,     # Line is off hook
  :congestion,  # Congestion (circuits busy)
  :flash,       # Flash hook
  :wink,        # Wink
  :option,      # Set a low-level option
  :radio_key,   # Key Radio
  :radio_unkey, # Un-Key Radio
  :progress,    # Indicate PROGRESS
  :proceeding,  # Indicate CALL PROCEEDING
  :hold,        # Indicate call is placed on hold
  :unhold,      # Indicate call is left from hold
  :vidupdate,   # Indicate video frame update
]

Adhearsion::Hooks::OnFailedCall.create_hook do |call|
  begin
    failure_reason = ASTERISK_FRAME_STATES[call.variable('REASON').to_i]
    ahn_log.call_failure.warn "Handling failure logic because an agent call failed with the state: #{failure_reason}"
    if [:failure, :busy, :congestion].include? failure_reason
      combined_next_tries, group_id, employee_id = call.variable 'next_tries', 'group_id', 'employee_id'
      if !combined_next_tries.blank?
        next_attempt, *next_tries = combined_next_tries.split '|'
        Server.find_by_name(THIS_SERVER).call_agent \
          :phone_number => next_attempt,
          :next_tries   => next_tries,
          :employee_id  => employee_id,
          :group_id     => group_id
      else
        ahn_log.call_failure.error "Agent unreachable because there are no more steps remaining! Giving up!"
      end
    else ahn_log.call_failure.warn "A call to an agent seems to have failed because they didn't answer."
    end
  rescue => e
    p e
    puts *e.backtrace
  end
end

# # Determines whether the answered call should actually give a call to the callee. 
# # We wouldn't want to give a call to the callee if another agent already picked
# # up the call.
# class AgentHistoryTracker
#   
#   cattr_reader :time_to_live, :lock, :chronicle
#   
#   @@time_to_live = 3
#   @@lock         = Mutex.new
#   @@chronicle    = []
#   
#   class << self
#     
#     def <<(unique_id)
#       cleanup!
#       atomically do
#         chronicle << {:expiration_time => time_to_live.from_now, :id => unique_id}
#       end
#     end
#     
#     def should_answer_call_with_id?(unique_id)
#       cleanup!
#       atomically do
#         return !chronicle.find { |record| record[:id] == unique_id }
#       end
#     end
#     
#     private
#     
#     def cleanup!
#       atomically do
#         chronicle.shift until chronicle.empty? || chronicle.first[:expiration_time] > Time.now
#       end
#     end
# 
#     def atomically(&synchronized_code)
#       lock.synchronize(&synchronized_code)
#     end
#   end
#   
# end

