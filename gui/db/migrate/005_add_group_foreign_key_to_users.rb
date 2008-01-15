class AddGroupForeignKeyToUsers < ActiveRecord::Migration
  def self.up
    add_column :employees, :group_id, :integer
  end

  def self.down
    remove_column :employees, :group_id
  end
end
