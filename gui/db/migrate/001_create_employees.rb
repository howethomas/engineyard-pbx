class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees do |t|
      t.string :name
      t.integer :time_zone
      t.string :extension

      t.timestamps
    end
  end

  def self.down
    drop_table :employees
  end
end
