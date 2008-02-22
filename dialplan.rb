=begin
When going to the group editor, view a list a groups and can specify their IVR extensions there
When you select a group, you view the Group editor as it is now with just one column, instead.

=end

login {
  
  group_id        = get_variable 'group_id'
  employee_id     = get_variable 'employee_id'
  customer_cookie = get_variable 'customer_cookie'
  
  p :emp => employee_id, :caller => customer_cookie, :group => group_id
  
  agent       = Employee.find employee_id
  queue_group = Group.find group_id
  
  waiting_members = variable("QUEUE_WAITING_COUNT(#{queue_group.name})").to_i
  
  if waiting_members > 0
    agent_login(employee_id, true) # true for "silent"
  else
    other_groups = employee.groups - [queue_group]
    if other_groups.find { |group| variable("QUEUE_WAITING_COUNT(#{group.name})").to_i > 0 }
      agent_login(employee_id, true)  # true for "silent"
    else
      +call_already_answered
    end
  end
}

call_already_answered {
  puts "It seems another agent has already answered this call!"
  play 'tt-weasels'
}

# if AgentHistoryTracker.should_answer_call_with_id? customer_cookie
#   AgentHistoryTracker << customer_cookie

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
  this_caller  = `uuidgen`.strip # Umm? Hackeyyy
  p [:this_caller, this_caller]
  
  if this_group && this_machine
    this_group.generate_calls this_machine, this_caller
    queue this_group.name # MUST SET A TIMEOUT!
    
    # voicemail this_group.name
  else
    # SERIOUS PROBLEMS!
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
    
    link.conferences 900..999
    
    link.on_premature_timeout { play 'are-you-still-there' }
    link.on_invalid { play 'invalid' }
    link.on_failure do
      play %w'vm-sorry one-moment-please'
      +other
    end
  end
}
