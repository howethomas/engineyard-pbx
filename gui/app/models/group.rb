class Group < ActiveRecord::Base
  
  validates_presence_of :name
  
  has_many :memberships
  has_many :employees, :through => :memberships
  
end
