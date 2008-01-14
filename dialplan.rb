ahn {
  
  choice = input 4, :timeout => 5.seconds, :play => 'engineyard/prompt'
  
  if (1..3).include? choice.to_i
    play 'hello-world'
  elsif employee = Employee.find_by_extension(choice)
    mobile_number = employee.mobile_number
    if mobile_number
      dial "SIP/trunk/#{mobile_number}", :callerid => callerid
    else
      # Say: Sorry, the person you're calling cannot be reached.
    end
  elsif (1_000...10_000).include? choice.to_i
    join choice
  end
}