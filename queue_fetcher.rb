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

require File.read(File.dirname(__FILE__) + "/.path_to_gui").chomp + '/config/environment.rb'
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
      CallFile.new(call_options).write_to_disk
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
    
  end
end

class CallFile
  
  ASTERISK_CALL_FILE_DIR = '/var/spool/asterisk/outgoing'
  CALLER_ID_NAME         = 'EY Sales'
  CALLER_ID_NUMBER       = 14097672813
  HANDLING_CONTEXT       = 'login'
  
  attr_reader :phone_number, :wait_time, :file_name, :agent_id, :employee_id, :customer_cookie
  def initialize(options)
    
    @phone_number    = options[:phone_number]
    @wait_time       = options[:wait_time] || 15
    @employee_id     = options[:employee_id]
    @customer_cookie = options[:customer_cookie]
    
    @file_name       = "#{Time.now.to_f}_#{rand(10_000_000)}.call"
    
  end
  
  def write_to_disk
    temp_file = "/tmp/#@file_name"
    File.open temp_file, "a" do |file|
      file.puts to_s
    end
    `mv #{temp_file} #{ASTERISK_CALL_FILE_DIR}`
  end
  
  def to_s
    <<-CALL_FILE_CONTENT
Channel: IAX2/voipms/#{phone_number}
MaxRetries: 1
WaitTime: #{wait_time}
Context: login
Extension: s
CallerID: "#{CALLER_ID_NAME}" <#{CALLER_ID_NUMBER}>
Set: customer_cookie=#{customer_cookie}
Set: employee_id=#{employee_id}
    CALL_FILE_CONTENT
  end
  
end
