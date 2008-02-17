END {

pbx1 = Server.find(:first)

Scheduler.for pbx1 do |event|
  begin
    puts "I got an event with ID #{event.id}"
    case event.name.to_sym
      when :call_agent
        puts "CALLING AGENT AT #{event.message}"
        CallFile.new(event.message).write_to_disk
      else
        STDERR.puts "Unrecognized event name #{event.name} with #{event.message}"
    end
    event.complete!
  rescue => exception
    STDERR.puts exception, *exception.backtrace
    sleep 0.2
  end
end

Scheduler.join

}

require File.join(File.dirname(__FILE__), *%w[ey-gui config environment.rb])

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
    thread_group.list.each &:join
  end
  
end

class CallFile
  
  ASTERISK_CALL_FILE_DIR = '/var/spool/asterisk/outgoing'
  # ASTERISK_CALL_FILE_DIR = '/Users/jicksta/Desktop'
  
  attr_reader :phone_number, :wait_time, :file_name#, :agent_id
  def initialize(phone_number, wait_time = 15)
    # @agent_id     = agent_id
    @phone_number = phone_number
    @wait_time    = wait_time
    @file_name    = "#{Time.now.to_f}_#{rand(10_000_000)}.call"
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
Context: from_queue_outbound
Extension: s
    CALL_FILE_CONTENT
  end
  
end