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
      # If the queue is now empty but we found another queue the person can join...
      menu 'engineyard/press-pound-to-accept-a-call-for-the', :timeout => 10.seconds do |link|
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
    dial_timeout = Setting.find_by_name('extension_dial_timeout').global_setting_override.value || 24
    dial "IAX2/voipms/#{mobile_number}", :caller_id => "18665189273", :for => dial_timeout, :confirm => true
    voicemail :employees => employee.id
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
    this_group.generate_calls this_machine
    queue(this_group.name).join! :timeout => this_group.settings.queue_timeout, :allow_transfer => :agent
    voicemail :groups => this_group.id
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

other {
  +sales
}
