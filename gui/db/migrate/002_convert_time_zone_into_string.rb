class ConvertTimeZoneIntoString < ActiveRecord::Migration
  def self.up
    remove_column :employees, :time_zone
    add_column :employees, :time_zone, :string
  end

  def self.down
    remove_column :employees, :time_zone
    add_column :employees, :time_zone, :integer
  end
end
