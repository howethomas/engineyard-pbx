class AddVactionFlagToUsers < ActiveRecord::Migration
  def self.up
    add_column :employees, :on_vacation, :boolean
  end

  def self.down
    remove_column :employees, :on_vaction
  end
end
