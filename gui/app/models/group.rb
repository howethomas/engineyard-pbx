class Group < ActiveRecord::Base
  
  validates_presence_of :name, :group_id, :employee_id
  
  has_many :memberships
  has_many :employees, :through => :memberships
  
end
