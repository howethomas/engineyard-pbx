PATH_TO_RAILS = File.expand_path(File.dirname(__FILE__) + '/../.path_to_gui')

Adhearsion::Configuration.configure do |config|
  
  config.enable_asterisk
  config.enable_rails :path => File.read(PATH_TO_RAILS).chomp, :env => :development
  
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
    
    def should_answer_call_with_id(unique_id)
      cleanup!
      atomically do
        return !chronicle.find { |record| record[:id] == unique_id }.nil?
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
