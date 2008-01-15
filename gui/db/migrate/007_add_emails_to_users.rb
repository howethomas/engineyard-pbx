class AddEmailsToUsers < ActiveRecord::Migration
  def self.up
    add_column :employees, :email, :string
  end

  def self.down
    remove_column :employees, :email, :string
  end
end
