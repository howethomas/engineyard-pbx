class AddMobileNumber < ActiveRecord::Migration
  def self.up
    add_column :employees, :mobile_number, :string
  end

  def self.down
    remove_column :employees, :mobile_number
  end
end
