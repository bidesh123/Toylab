class TableId < ActiveRecord::Migration
  def self.up
    add_column :cards, :table_id, :integer
  end

  def self.down
    remove_column :cards, :table_id
  end
end
