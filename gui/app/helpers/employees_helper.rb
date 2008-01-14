module EmployeesHelper
  def select_timezone
    time_zone_select 'employee', 'time_zone', TZInfo::Timezone.all.sort, :model => TZInfo::Timezone, :default => "America/Los_Angeles"
  end
  
  def alert!
    image_tag "alert.gif"
  end
  
end
