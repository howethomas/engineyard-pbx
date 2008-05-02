context :employees do |context|
  Employee.find(:all).each do |employee|
    context.mailbox employee.extension do |mailbox|
      mailbox.pin_number 1337
      mailbox.name employee.name
      mailbox.email employee.email
    end
  end
end

context :groups do |context|
  Group.find(:all).each do |group|
    context.mailbox group.id do |mailbox|
      mailbox.pin_number 1337
      mailbox.name group.name
      mailbox.email group.email
    end
  end
end

############################################################################
############################################################################

signature = "EngineYard Phone System"

# execute_after_email "netcat 192.168.1.2 12345"
# greeting_maximum 1.minute
# time_jumped_with_skip_key 3.seconds # milliseconds!
# logging_in do |config|
#   config.maximum_attempts 3
# end

recordings do |config|
  config.format :wav # ONCE YOU PICK A FORMAT, NEVER CHANGE IT UNLESS YOU KNOW THE CONSEQUENCES!
  config.allowed_length 3.seconds..5.minutes
  config.maximum_silence 10.seconds
  # config.silence_threshold 128 # wtf?
end

emails do |config|
  config.command "/usr/sbin/sendmail -f pbx@engineyard.com.com -t"
  config.from :name => signature, :email => "pbx@engineyard.com"
  config.attach_recordings true
  config.subject "New voicemail for #{config[:email]} from #{config[:caller_id]}"
  config.body <<-BODY
#{config[:name]}:

The caller #{config[:caller_id]} left you a #{config[:duration]} long voicemail
on #{config[:date]}.

#{ "The recording is attached to this email.\n" if config.attach_recordings? }
    - #{signature}
  BODY
end
