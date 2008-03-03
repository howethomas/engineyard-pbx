login {
  
  @group_id        = get_variable 'group_id'
  @employee_id     = get_variable 'employee_id'
  @customer_cookie = get_variable 'customer_cookie'
  
  ahn_log :emp => @employee_id, :caller => @customer_cookie, :group => @group_id
  
  @agent       = Employee.find @employee_id
  @queue_group = Group.find @group_id
  
  @queue = queue(@queue_group.name)
  
  if @queue.empty?
    @other_groups = @agent.groups - [@queue_group]
    @queue = @other_groups.find { |group| !queue(group.name).empty? }
    if @queue
      menu 'you-sound-cute', :timeout => 10.seconds do |link|
        link.confirmed '#'
      end
    else
      +call_already_answered
    end
  else
    menu 'you-sound-cute', :timeout => 10.seconds do |link|
      link.confirmed '#'
    end
  end
}

confirmed {
  queue(@queue.name).agents.login!(@employee_id, :silent => true)
}

call_already_answered {
  puts "It seems another agent has already answered this call!"
  play 'tt-weasels'
}

employee_tree {
  menu do |link|
    link.employee(*Employee.find(:all).map(&:extension))
  end
}

employee {
  employee = Employee.find_by_extension extension
  mobile_number = employee.mobile_number if employee
  
  if mobile_number
    # dial "SIP/voipms/#{mobile_number}", :caller_id => "104097672813"
    puts "DIALING #{mobile_number}! mocked out"
  else
    play %w'sorry number-not-in-db'
    +employee_tree
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
    this_group.generate_calls(this_machine, this_caller)
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
  password = SettingsManager[:conference_password]
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
    
    link.employee_tree 9
    link.conferences 800..899
    
    link.group_dialer(*Group.find(:all).map(&:ivr_option))
    
    link.on_premature_timeout { play 'are-you-still-there' }
    link.on_invalid { play 'invalid' }
    link.on_failure do
      play %w'vm-sorry one-moment-please'
      +other
    end
  end
}