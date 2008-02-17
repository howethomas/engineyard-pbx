# IVR editor
# Queue (group) editor

=begin
billing@engineyard.com
Edit groups in Employee edit view

add groups, define extensions

When going to the group editor, view a list a groups and can specify their IVR extensions there
When you select a group, you view the Group editor as it is now with just one column, instead.

=end

from_queue_outbound {
  menu "hello-world", :timeout => 1.minute do |link|
    link.login '#'
  end
}

login {
  # TODO: Set the call type here!
  add_queue_member 'ey', 'Agent/100'
  agent_login 100, false
}

from_pstn_old {
  menu 'engineyard/prompt', :tries => 3, :timeout => 7 do |link|
    link.sales        1
    link.tech_support 2
    link.finance      3
    link.other        0
    
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

from_codemecca { +from_pstn }

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

sales {
  play 'privacy-please-stay-on-line-to-be-connected'
  # Enter the sales queue
}

group_dialer {
  
  play 'privacy-please-stay-on-line-to-be-connected'
  # Enter the tech support queue
}

# Should be a group with Riki (or any other employee) as a member.
finance {
  play 'privacy-please-stay-on-line-to-be-connected'
  riki = Employee.find_by_name "Riki Crusha"
  dial "IAX2/jay-trunk-out/#{riki.mobile_number}", :caller_id => "14097672813"
}

conferences {
  play 'conf-enteringno', extension
  join extension
}

other {
  +sales
}

# This is mostly my debug context.
from_internal {
  
  extension_map = {
    '250' => "jay-desk-650"
  }
  
  case extension.to_s
    when *extension_map.keys  
      dial "SIP/#{extension_map[extension.to_s]}"
    when /^18(00|88|77)\d{7}$/
      puts "Dialing 'toll free' number"
      dial "IAX2/jay-trunk-out/#{extension}", :caller_id => 1_409_767_2813
    when /^\d{10}$/
      puts "here??!??!?"
      dial "IAX2/jay-trunk-out/1#{extension}", :caller_id => 1_409_767_2813
    when /^\d{11}$/
      dial "IAX2/jay-trunk-out/#{extension}", :caller_id => 1_409_767_2813
    else
      play 'invalid'
  end
  
}
