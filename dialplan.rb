
from_trunk {
  case extension
    when 6903:
      +billing
   else
      +ivr
   end
}


billing {
   sleep 1
   this_group   = Group.find_by_ivr_option "3"
   this_machine = Server.find_by_name THIS_SERVER

   ahn_log "This group   : #{this_group.name}"
   ahn_log "This machine : #{this_machine.name}"

   if this_group && this_group.empty?
     voicemail :groups => this_group.id
   elsif this_group && this_machine
     this_queue = queue this_group.name

     agents_who_are_busy_handling_calls = this_queue.agents.select(&:logged_in?).map(&:id).map(&:to_s)
     ahn_log "These guys are busy handling calls: #{agents_who_are_busy_handling_calls * ', '}"

     agents_available = this_group.members.select do |agent|
       agent.available? && !agents_who_are_busy_handling_calls.include?(agent.id.to_s)
     end

     if agents_available.any?
       play 'privacy-please-stay-on-line-to-be-connected'
       this_group.generate_calls(this_machine, :exclude => agents_who_are_busy_handling_calls)
       ahn_log "I supposedly generated the calls!"
       this_queue.join! :timeout => this_group.settings.queue_timeout, :allow_transfer => :agent
     else
       play 'all-reps-busy'
     end
     play 'engineyard/group-voicemail-message'
     voicemail :groups => this_group.id, :skip => true
   else
     ahn_log.dialplan.error "GROUP AND MACHINE NOT FOUND!!!"
   end

 }


voicemail_checker {
  ahn_log.dialplan "Entering voicemail checking system"
  3.times do
    user_extension = input :play => "engineyard/pls-enter-extension", :timeout => 7
    ahn_log.dialplan "Received extension #{user_extension}"
    employee = Employee.find_by_extension user_extension
    unless employee
      play 'pbx-invalid'	# I am sorry, that's not a valid extension. Please try again.
      next
    end
    user_password = input :play => "agent-pass"
    if user_password.to_s != employee.voicemail_pin.to_s
      play 'engineyard/invalid-pin'
      next
    end
    voicemail_main :context => "employees", :mailbox => user_extension, :authenticate => false
  end
}



ivr {
  sleep 1
  
  all_groups = Group.find :all, :order => "ivr_option"
  
  on_failure_group_ivr_option = all_groups.detect { |group| group.name.downcase == 'salescalls' }.ivr_option rescue 0
  
  menu 'engineyard/welcome', 'engineyard/prompt', :tries => 4, :timeout => 7 do |link|
    
    link.employee_tree 9
    link.voicemail_login 10
    link.conferences 8000..8999
    
    link.group_dialer(*all_groups.map(&:ivr_option))
    
    link.on_premature_timeout do
      # play 'are-you-still-there'
    end
    
    link.on_invalid { play 'invalid' }
    link.on_failure do
      play %w'vm-sorry one-moment-please'
      jump_to(group_dialer, :extension => on_failure_group_ivr_option)
    end
  end
}

voicemail_login {
  voicemail_main({:context=>"employees"})
}

login {
  
  enable_feature :attended_transfer, :context => "transfer_context"
  
  @group_id    = get_variable 'group_id'
  @employee_id = get_variable 'employee_id'
  
  ahn_log :emp => @employee_id, :group => @group_id
  
  @agent       = Employee.find @employee_id
  @queue_group = Group.find @group_id
  
  @queue = queue(@queue_group.name)
  
  if @queue.empty?
    @other_groups = @agent.groups - [@queue_group]
    @queue = @other_groups.find { |group| !queue(group.name).empty? }
    if @queue
      # If the queue is now empty but we found another queue the person can join...
      group_sound_file_name = @queue.name.gsub(/\s+/, '_').underscore.dasherize
      menu 'engineyard/to-accept-a-call-for', group_sound_file_name, 'press-pound', :timeout => 30.seconds do |link|
        link.confirmed '#'
      end
    else
      +call_already_answered
    end
  else
    group_sound_file_name = @queue_group.name.gsub(/\s+/, '_').underscore.dasherize
    menu 'engineyard/to-accept-a-call-for', group_sound_file_name, 'press-pound', :timeout => 10.seconds do |link|
      link.confirmed '#'
    end
  end
}

confirmed {
  q = queue @queue.name
  +call_already_answered if q.empty?
  q.agents.login!(@employee_id, :silent => true)
}

call_already_answered {
  ahn_log "#{@agent.name} answered after the queue had become empty."
  play 'engineyard/call-already-answered'
}

employee_tree {
  sleep 0.4 # The enter-ext-of-person sound file starts very abruptly. This delays it.
  menu 'enter-ext-of-person', :timeout => 10.seconds, :tries => 3 do |link|
    link.employee(*Employee.find(:all).map(&:extension))
    
    link.employee_directory 1
    link.on_invalid do
      play 'invalid'
    end
    
    link.on_failure { +ivr }
  end
}

employee_directory {
  sleep 0.4 # The enter-ext-of-person sound file starts very abruptly. This delays it.
  execute("Directory", "employees")
}

employee {
  
  enable_feature :attended_transfer, :context => "transfer_context"
  
  employee = Employee.find_by_extension extension
  if employee.nil?
    play %w'sorry number-not-in-db'
    +employee_tree
  end
  if employee.available?
    # We found an employee, and he's available.  Call him if there's a mobile number, 
    # or just forward to extension if not.
    mobile_number = employee.mobile_number.strip if employee
    if mobile_number and HOSTNAME.chomp == 'pbx-1'
      trunk = "ZAP/G1/#{mobile_number}&SIP/#{extension}"
      use_macro = true        # Need to use macros when callinng PSTN phones, otherwise not.
    else
      trunk = "SIP/#{extension}"
      use_macro = false       # No need to use a macro when calling a SIP phone
    end
    play 'pls-hold-while-try'
    dial_timeout = Setting.find_by_name('extension_dial_timeout').global_setting_override.value || 24
    real_cid = callerid
    dial_start_time = Time.now
    if use_macro
      confirm_prompt = %w[engineyard/to-accept-a-call-for extension] + extension.to_s.split('').map { |x| "digits/#{x}" } + %w"press-pound"
      dial trunk, :caller_id => "8665189273", :for => dial_timeout, :confirm => {:play => confirm_prompt}, :options => "mt"
    else
      dial trunk, :caller_id => "8665189273", :for => dial_timeout, :options => "t"
    end
    
    # Trying a different approach here.  If we've gotten this far, it's because the 
    # dial timed out, or people are about to hang up. Let's just a few seconds to see if
    # they hangup by themselves. We need to do this because.... from Jay    
    # This makes my cry inside. With the M() Dial option (:confirm to dial()), last_call_successful? always
    # returns true. We therefore have to resort to BS like this...
    sleep 3     # Wait three seconds
    variable "CALLERID(num)" => real_cid
    voicemail :employees => employee.extension, :greeting => :unavailable
  else
    variable "CALLERID(num)" => real_cid
    voicemail :employees => employee.extension, :greeting => :unavailable
  end
}

transfer_context {
  employee = Employee.find_by_extension extension
  number = (employee ? employee.mobile_number.strip : extension).to_s
    
  number = "1#{number}" if number.length == 10
  
  if number.length < 11
    play 'engineyard/sorry-transfer-failed'
  else
    dial "ZAP/G1/#{number}"
    dial "SIP/#{number}@vitel-outbound", :options => "t" if last_dial_unsuccessful?
    dial "SIP/70.42.72.49/11284400#{number}", :options => "t" if last_dial_unsuccessful?
  end
}

group_dialer {
 enable_feature :attended_transfer, :context => "transfer_context"

  this_group   = Group.find_by_ivr_option extension
  this_machine = Server.find_by_name THIS_SERVER
  
  ahn_log "This group   : #{this_group.name}"
  ahn_log "This machine : #{this_machine.name}"
  
  if this_group && this_group.empty?
    voicemail :groups => this_group.id
  elsif this_group && this_machine
    this_queue = queue this_group.name
    
    agents_who_are_busy_handling_calls = this_queue.agents.select(&:logged_in?).map(&:id).map(&:to_s)
    ahn_log "These guys are busy handling calls: #{agents_who_are_busy_handling_calls * ', '}"
    
    agents_available = this_group.members.select do |agent|
      agent.available? && !agents_who_are_busy_handling_calls.include?(agent.id.to_s)
    end
    
    if agents_available.any?
      play 'privacy-please-stay-on-line-to-be-connected'
      this_group.generate_calls(this_machine, :exclude => agents_who_are_busy_handling_calls)
      ahn_log "I supposedly generated the calls!"
      this_queue.join! :timeout => this_group.settings.queue_timeout, :allow_transfer => :agent
    else
      play 'all-reps-busy'
    end
    play 'engineyard/group-voicemail-message'
    voicemail :groups => this_group.id, :skip => true
      
  else
    ahn_log.dialplan.error "GROUP AND MACHINE NOT FOUND!!!"
  end
}

conferences {
  3.times {
    pin = input :play => %w"pls-enter-conf-password then-press-pound"
    valid_pin = Setting.find_by_name('primary_conference_pin').global_setting_override.value
  
    +enter_conference if pin == valid_pin
  
    valid_pin = Setting.find_by_name('secondary_conference_pin').global_setting_override.value
    if !valid_pin.blank? && pin == valid_pin
      play 'engineyard/conference-pin-deprecated'
      +enter_conference
    else
      play 'conf-invalidpin'
    end
  }
  
  play %w'pls-try-call-later vm-goodbye'
}

enter_conference {
  play "entering-conf-number", extension
  join extension
}

