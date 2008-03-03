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

# Determines whether the answered call should actually give a call to the callee. 
# We wouldn't want to give a call to the callee if another agent already picked
# up the call.
class AgentHistoryTracker
  
  cattr_reader :time_to_live, :lock, :chronicle
  
  @@time_to_live = 3
  @@lock         = Mutex.new
  @@chronicle    = []
  
  class << self
    
    def <<(unique_id)
      cleanup!
      atomically do
        chronicle << {:expiration_time => time_to_live.from_now, :id => unique_id}
      end
    end
    
    def should_answer_call_with_id?(unique_id)
      cleanup!
      atomically do
        return !chronicle.find { |record| record[:id] == unique_id }
      end
    end
    
    private
    
    def cleanup!
      atomically do
        chronicle.shift until chronicle.empty? || chronicle.first[:expiration_time] > Time.now
      end
    end

    def atomically(&synchronized_code)
      lock.synchronize(&synchronized_code)
    end
  end
  
end
