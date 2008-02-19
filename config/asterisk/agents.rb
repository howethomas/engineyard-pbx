Employee.find(:all) do |employee|
  agent employee.id(:name => employee.name)
end

persistent_agents false
allow_star_to_hangup false