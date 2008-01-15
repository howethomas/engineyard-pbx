class Employee < ActiveRecord::Base
  
  validates_numericality_of :extension
  validates_presence_of :name, :extension
  
  def self.with_extension_like(beginning)
    find :all, :conditions => "extension LIKE \"#{beginning}%\""
  end
  
end