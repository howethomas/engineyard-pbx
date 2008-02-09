puts "Loading employee"
class Employee < ActiveRecord::Base
  
  validates_numericality_of :extension
  validates_presence_of :name, :extension
  
  has_many :memberships
  has_many :groups, :through => :memberships
  
  def self.with_extension_like(beginning)
    find :all, :conditions => "extension LIKE \"#{beginning}%\""
  end
  
end