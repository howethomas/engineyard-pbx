class RemoveGroupId < ActiveRecord::Migration
  def self.up
    remove_column :employees, :group_id
  end

  def self.down
    add_column :employees, :group_id, :integer
  end
end
