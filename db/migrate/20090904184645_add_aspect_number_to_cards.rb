class AddAspectNumberToCards < ActiveRecord::Migration
  def self.up
    rename_column :cards, :number, :item_number
    add_column :cards, :aspect_number, :integer
  end

  def self.down
    rename_column :cards, :item_number, :number
    remove_column :cards, :aspect_number
  end
end
