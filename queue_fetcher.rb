END {

pbx1 = Server.find(:first)

Scheduler.for pbx1 do |event|
  puts "I got an event with ID #{event.id}"
  begin
    QueueMessageHandler.send(event.name, event.message)
  rescue => exception
    STDERR.puts exception, *exception.backtrace
    sleep 0.2
  ensure
    event.complete!
  end
end

Scheduler.join

}

path_to_gui_file = File.expand_path(File.dirname(__FILE__) + '/../.path_to_gui')
PATH_TO_RAILS = if File.exists? path_to_gui_file
  File.read(path_to_gui_file).strip
else
  File.expand_path(File.dirname(__FILE__) + '/../ey-gui')
end

require PATH_TO_RAILS + "/config/environment.rb"
require File.dirname(`which ahn`) + "/../lib/adhearsion"
require 'adhearsion/voip/asterisk/config_generators/queues.conf.rb'
require 'adhearsion/voip/asterisk/config_generators/agents.conf.rb'

class Scheduler
  
  cattr_accessor :thread_group
  self.thread_group = ThreadGroup.new
  
  def self.for(recipient, tasks_property=:actions, &block)
    puts "Initializing Scheduler for #{recipient}"
    this_handler = Thread.new do

      sleep_time = 2.seconds.to_i
      
      loop do
        puts "In loop"
        events = recipient.__send__(tasks_property)

        if events.empty?: sleep sleep_time
        else events.each(&block)
        end
        
        recipient.reload
      end
    end
    thread_group.add this_handler
  end
  
  def self.join
    thread_group.list.each(&:join)
  end
  
end


class QueueMessageHandler
  class << self
    
    def call_agent(message)
      call_options = YAML.load message
      puts "CALLING AGENT WITH #{call_options.inspect}"
      AgentReachingCallFile.new(call_options).write_to_disk
    end
    
    CONFIG_FILE_MODULE_NAMES = {
      "queues" => "app_queue",
      "agents" => "chan_agent"
    }
    CONFIG_FILE_MODULE_NAMES.default = ''
    
    def regenerate_config_file(config_name)
      dynamic_config_file = File.dirname(__FILE__) + "/config/asterisk/#{config_name}.rb"
      config_file_code = File.read dynamic_config_file
      
      config_class_name = config_name.camelize
      config_generator = Adhearsion::VoIP::Asterisk::ConfigFileGenerators.const_get(config_class_name).new
      config_generator.instance_eval(config_file_code)
      
      asterisk_config_file = "/etc/asterisk/#{config_name}.conf"
      if File.exists?(asterisk_config_file)
        File.open(asterisk_config_file, "w") do |file|
          file.write config_generator
        end
        `asterisk -rx reload #{CONFIG_FILE_MODULE_NAMES[config_name]}`
      else
        puts asterisk_config_file + " does not exist! Is Asterisk installed???"
      end
    end
    
    def introduce(message)
      source, destination = message.split '|'
      IntroductionCallFile.new(source, destination).write_to_disk
    end
    
  end
end

class CallFile
  
  CALLER_ID_NUMBER = 1_866_518_9273 # EY Main #. MUST BE GROUP-SPECIFIC!
  
  def write_to_disk
    temp_file = "/tmp/#{new_call_file_name}"
    File.open temp_file, "a" do |file|
      file.puts contents
    end
    `mv #{temp_file} #{asterisk_call_file_directory}`
  end
  
  def contents
    raise NotImplementedError
  end
  
  protected
  
  def outbound_trunk
    'IAX2/voipms/%s'
  end
  
  private
  
  def new_call_file_name
    "#{Time.now.to_f}_#{rand(10_000_000)}.call"
  end
  
  def asterisk_call_file_directory
    '/var/spool/asterisk/outgoing'
  end
  
end

class AgentReachingCallFile < CallFile
  
  attr_reader :phone_number, :wait_time, :agent_id, :employee_id,
              :customer_cookie, :group_id, :group_name, :caller_id_num
  
  def initialize(options)
    
    @phone_number    = options[:phone_number]
    @wait_time       = options[:wait_time] || 35
    @employee_id     = options[:employee_id]
    @customer_cookie = options[:customer_cookie]
    @group_id        = options[:group_id]
    
    group_instance   = Group.find @group_id 
    @group_name      = group_instance.name
    @caller_id_num   = group_instance.caller_id || Group::MAIN_ENGINEYARD_NUMBER
    
  end
  
  def contents
    <<-CALL_FILE_CONTENT
Channel: #{outbound_trunk % phone_number}
MaxRetries: 0
WaitTime: #{wait_time}
Context: #{handling_context}
Extension: s
CallerID: #{caller_id}
Set: customer_cookie=#{customer_cookie}
Set: employee_id=#{employee_id}
Set: group_id=#{group_id}
    CALL_FILE_CONTENT
  end
  private
  
  def caller_id
    %("EY #{group_name}" <#{caller_id_num}>)
  end
  
  def handling_context
    'login'
  end
  
end

class IntroductionCallFile < CallFile
  
  attr_reader :source, :destination
  def initialize(source, destination)
    @source, @destination = source, destination
  end
  
  def contents
    <<-CALL_FILE_CONTENT
Channel: #{outbound_trunk % source}
MaxRetries: 0
Application: Dial
Data: #{outbound_trunk % destination}
CallerID: "EngineYard" <#{source}>
    CALL_FILE_CONTENT
  end
end
