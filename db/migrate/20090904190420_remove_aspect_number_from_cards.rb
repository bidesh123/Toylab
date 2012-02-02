class RemoveAspectNumberFromCards < ActiveRecord::Migration
  def self.up
    remove_column :cards, :aspect_number
  end

  def self.down
    add_column :cards, :aspect_number, :integer
  end
end
