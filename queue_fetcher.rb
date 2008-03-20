
path_to_gui_file = File.expand_path(File.dirname(__FILE__) + '/.path_to_gui')
PATH_TO_RAILS = if File.exists? path_to_gui_file
  File.read(path_to_gui_file).strip
else
  File.expand_path(File.dirname(__FILE__) + '/../ey-gui')
end

require PATH_TO_RAILS + "/config/environment.rb"

ahn_path = File.dirname(`which ahn`) + "/../lib/adhearsion"
require File.exist?(ahn_path) ? ahn_path : '/usr/local/adhearsion/lib/adhearsion'
require 'adhearsion/voip/asterisk/config_generators/queues.conf.rb'
require 'adhearsion/voip/asterisk/config_generators/agents.conf.rb'
require 'adhearsion/voip/asterisk/config_generators/voicemail.conf.rb'

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
      AgentReachingCallFile.create call_options
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
        ahn_log.messages.error asterisk_config_file + " does not exist! Is Asterisk installed???"
      end
    end
    
    def introduce(message)
      source, destination = message.split '|'
      IntroductionCallFile.new(source, destination).write_to_disk
    end
    
  end
end

class Trunk
  
  @@instances = []
 
  class << self
    def sequence_for_number(number)
      @@instances.map { |trunk| trunk.format(number) }
    end
  end
  
  attr_reader :name
  def initialize(name, &block)
    raise LocalJumpError, "block not supplied!" unless block_given?
    @number_formatter = block
    @@instances << self
  end
  
  def format(number)
    @number_formatter.call(number)
  end
  
end

class CallFile
  
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
  
  private
  
  def new_call_file_name
    "#{Time.now.to_f}_#{rand(10_000_000)}.call"
  end
  
  def asterisk_call_file_directory
    '/var/spool/asterisk/outgoing'
  end
  
end

class AgentReachingCallFile < CallFile
  
  class << self
    def create(options)
      if options.has_key? :next_tries
        ahn_log "RETRYING AGENT WITH #{options.inspect}"
        RetryAgentReachingCallFile.new(options).write_to_disk
      else
        FirstTimeAgentReachingCallFile.new(options).write_to_disk
      end
    end
  end
  
  def initialize(options)
    @wait_time       = options[:wait_time] || 35
    @employee_id     = options[:employee_id]
    @group_id        = options[:group_id]
    
    # The following variables are used to determine the CallerID name.
    @group_instance  = Group.find @group_id 
    @group_name      = @group_instance.name
    @caller_id_num   = @group_instance.caller_id || Group::MAIN_ENGINEYARD_NUMBER
  end
  
  def contents
    <<-CALL_FILE_CONTENT
Extension: s
MaxRetries: 0
Context: #{handling_context}
CallerID: #{caller_id}
Channel: #@channel
WaitTime: #@wait_time
Set: employee_id=#@employee_id
Set: group_id=#@group_id
Set: next_tries=#@next_tries
    CALL_FILE_CONTENT
  end
  
  protected
  
  def caller_id
    %("EY #@group_name" <#@caller_id_num>)
  end
  
  def handling_context
    'login'
  end
  
end

class FirstTimeAgentReachingCallFile < AgentReachingCallFile
  def initialize(options)
    super
    
    @phone_number = options[:phone_number]
    @sequence   = Trunk.sequence_for_number @phone_number
    
    @channel    = @sequence.pop
    @next_tries = @sequence.join '|'
    ahn_log @next_tries
  end
end

class RetryAgentReachingCallFile < AgentReachingCallFile
  def initialize(options)
    super
    @channel    = options[:phone_number]
    @next_tries = options[:next_tries]
  end
end

class IntroductionCallFile < CallFile
  
  attr_reader :source, :destination
  def initialize(source, destination)
    @source, @destination = source, destination
    
    @channel = Trunk.sequence_for_number(source).first
    @data    = Trunk.sequence_for_number(destination).first
  end
  
  def contents
    <<-CALL_FILE_CONTENT
Channel: #@channel
MaxRetries: 0
Application: Dial
Data: #@data
CallerID: "EngineYard" <#{source}>
    CALL_FILE_CONTENT
  end
end


#### BELOW IS THE IMPLEMENTATION!!!

if `hostname`.starts_with? 'pbx'
  # Trunk.new("VoIP.ms Debug Account") { |number| "IAX2/#{number}@jay-trunk-out" }
  Trunk.new("Vitelity") { |number| "SIP/#{number}@vitel-outbound" }
else
  Trunk.new("Nufone")   { |number| "IAX2/vm@nufone/#{number}" }
  Trunk.new("VoIP.ms")  { |number| "IAX2/voipms/#{number}"   }
end

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
