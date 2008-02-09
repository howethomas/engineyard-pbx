class AddIvrOptionsToGroups < ActiveRecord::Migration
  def self.up
    add_column :groups, :ivr_option, :integer
  end

  def self.down
    remove_column :groups, :ivr_option
  end
end
