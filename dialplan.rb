ahn {
  
  %w[1-ey-greet 2-sales 3-techsupport
     4-finance 5-everything-else].each do |sound_file|
    play "engineyard/#{sound_file}"
  end
  
  # Employee.find(:all)
}