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

login {
  
  @group_id        = get_variable 'group_id'
  @employee_id     = get_variable 'employee_id'
  
  ahn_log :emp => @employee_id, :group => @group_id
  
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
    group_sound_file_name = "engineyard/" << @queue_group.name.gsub(/\s+/, '_').underscore.dasherize
    menu 'engineyard/press-pound-to-accept-a-call-for-the', group_sound_file_name, :timeout => 10.seconds do |link|
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
  play 'sorry-no-more-calls-waiting'
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
    play 'pls-hold-while-try'
    dial "IAX2/voipms/#{mobile_number}", :caller_id => "18665189273"
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
  
  if this_group && this_machine
    this_group.generate_calls(this_machine)
    queue(this_group.name).join! :timeout => 90.seconds, :allow_transfer => :agent
    # voicemail this_group.name
  else
    ahn_log.dialplan.error "GROUP AND MACHINE NOT FOUND!!!"
  end
}

conferences {
  join extension
}

other {
  +sales
}
