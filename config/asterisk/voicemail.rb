context :employees do |context|
  Employee.find(:all).each do |employee|
    context.mailbox do |mailbox|
      mailbox.mailbox_number employee.id
      mailbox.pin_number 1337
      mailbox.name employee.name
      mailbox.email employee.email
    end
  end
end

context :groups do |context|
  Group.find(:all).each do |group|
    context.mailbox do |mailbox|
      mailbox.mailbox_number group.id
      mailbox.pin_number 1337
      mailbox.name group.name
      mailbox.email group.email
    end
  end
end

############################################################################
############################################################################

signature = "Your Friendly Phone System"

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
  config.from :name => signature, :email => "noreply@adhearsion.com"
  config.attach_recordings true
  config.body <<-BODY
Dear #{email[:name]}:

The caller #{email[:caller_id]} left you a #{email[:duration]} long voicemail
(number #{email[:message_number]}) on #{email[:date]} in mailbox #{email[:mailbox]}.

#{ "The recording is attached to this email.\n" if email.attach_recordings? }
    - #{signature}
  BODY
end
