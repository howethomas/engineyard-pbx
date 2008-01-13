puts "got here in em"
class Employee < ActiveRecord::Base
  validates_numericality_of :extension
  validates_presence_of :name, :extension
end