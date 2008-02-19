persistent_members true

for group in Group.find :all

  queue group.name do |q|

    for member in group.employees
      q.member member.id
    end
  
    q.join_empty true # Mandatory!
  
    q.ring_timeout 15.seconds
    q.retry_after_waiting 5.seconds
    
    q.queue_status_announce_frequency 1.5.minutes

    q.periodically_announce "queue-periodic-announce", :every => 1.minute
    
    q.leave_when_empty true

    # TODO: These should be combined
    q.report_hold_time false
    q.announce_hold_time false

  end
  
end