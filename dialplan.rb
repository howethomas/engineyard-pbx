ahn {
  
  @choice = input 4, :timeout => 4.seconds, :play => 'engineyard/prompt'
  puts "choice: #{@choice.inspect}"
  
  case @choice.to_i
    when 200...300: +employees
    when 1      
      # IMPLEMENT GROUP DIALING
      # queue :sales
    when 2 
      # tech support
    when 3
      # finance
    when 0
      # operator
  end
}

employees {
  puts "Dialing an employee!"
  
  employee = Employee.find_by_extension @choice
  mobile_number = employee.mobile_number if employee
  
  if mobile_number
    #dial "SIP/voipms/#{mobile_number}", :callerid => callerid
    puts "DIALING #{mobile_number}! mocked out"
  else
    play 'invalid'
    +ahn
  end

}

internal {
  # Only allow internal users to dial into conferences
  case extension
    when 200...300
    when 1_000...10_000
  end
}

error_recovery {
  
}