login {
  
  group_id        = get_variable 'group_id'
  employee_id     = get_variable 'employee_id'
  customer_cookie = get_variable 'customer_cookie'
  
  ahn_log :emp => employee_id, :caller => customer_cookie, :group => group_id
  
  agent       = Employee.find employee_id
  queue_group = Group.find group_id
  
  this_queue = queue queue_group.name
  
  if this_queue.empty?
    other_groups = agent.groups - [queue_group]
    needy_queue  = other_groups.find { |group| queue(group.name).waiting_count > 0 }
    if needy_queue
      confirmation = input 1, :timeout => 4.seconds, :play => 'you-sound-cute'
      if confirmation == '#'
        queue(needy_queue.name).agents.login!(employee_id, :silent => true)
      end
    else
      +call_already_answered
    end
  else
    this_queue.agents.login! employee_id, :silent => true
  end
}

call_already_answered {
  puts "It seems another agent has already answered this call!"
  play 'tt-weasels'
}

employee {
  employee = Employee.find_by_extension extension
  mobile_number = employee.mobile_number if employee
  
  if mobile_number
    # dial "SIP/voipms/#{mobile_number}", :caller_id => "104097672813"
    puts "DIALING #{mobile_number}! mocked out"
  else
    play %w'sorry number-not-in-db'
    +ahn
  end

}

group_dialer {
  play 'privacy-please-stay-on-line-to-be-connected'
  
  this_group   = Group.find_by_ivr_option extension
  p [:this_group, this_group]
  this_machine = Server.find_by_name THIS_SERVER
  p [:this_machine, this_machine]
  this_caller  = `uuidgen`.strip
  p [:this_caller, this_caller]
  
  if this_group && this_machine
    this_group.generate_calls this_machine, this_caller
    queue(this_group.name).join! :timeout => 90.seconds, :allow_transfer => :agent
    # voicemail this_group.name
  else
    ahn_log.dialplan.error "GROUP AND MACHINE NOT FOUND!!!"
  end
}

conferences {
  # SINCE THIS IS A PUBLIC-FACING CONFERENCE BRIDGE, THERE SHOULD BE 
  # A GLOBAL ENGINEYARD PASSWORD TO ACCESS IT. TRUSTWORTHY PEOPLE = 
  # WON'T NEED TO ENTER THE PASSWORD. THE PASSWORD CAN BE CHANGED IN
  # THE WEB INTERFACE
  password = OptionsManager[:monkey].to_s
  tries = 0
  while tries < 3
    attempt = input password.length, :play => "please-enter-password"
    if attempt.to_s == password
      tries = 3
      join extension
    else
      tries += 1
    end
  end
}

other {
  +sales
}

ivr {
  menu 'engineyard/prompt', :tries => 3, :timeout => 7 do |link|
    link.group_dialer 1,2,3,4,5 # Group.find(:all).map(&:ivr_extension)
    
    link.employee *Employee.find(:all).map(&:extension)
    
    link.conferences 800..899
    
    link.on_premature_timeout { play 'are-you-still-there' }
    link.on_invalid { play 'invalid' }
    link.on_failure do
      play %w'vm-sorry one-moment-please'
      +other
    end
  end
}



# if AgentHistoryTracker.should_answer_call_with_id? customer_cookie
#   AgentHistoryTracker << customer_cookie