unless defined? Adhearsion
  require 'rubygems'
  gem 'adhearsion', '>= 0.7.999'
  require 'adhearsion' 
end

path_to_gui_file = File.expand_path(File.dirname(__FILE__) + '/../.path_to_gui')
PATH_TO_RAILS = if File.exists? path_to_gui_file
  File.read(path_to_gui_file).strip
else
  File.expand_path(File.dirname(__FILE__) + '/../../ey-gui')
end

Adhearsion::Configuration.configure do |config|
  
  config.logging :level => :debug
  
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

Adhearsion::Hooks::OnFailedCall.create_hook do |call|
  begin
    failure_reason = call.failed_reason
    if [:failure, :busy, :congestion].include? failure_reason
      ahn_log.call_failure.warn "Attemping failure recovery because an agent login failed with the state: #{failure_reason.inspect}"
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

Adhearsion::Initializer.start_from_init_file(__FILE__, File.dirname(__FILE__) + "/..")