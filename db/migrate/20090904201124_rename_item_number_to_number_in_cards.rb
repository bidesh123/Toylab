class RenameItemNumberToNumberInCards < ActiveRecord::Migration
  def self.up
    rename_column :cards, :item_number, :number
  end

  def self.down
    rename_column :cards, :number, :item_number
  end
end
