class AddListsAndActsAsList < ActiveRecord::Migration
  def self.up
    add_column :cards, :position, :integer
    add_column :cards, :list_id, :integer
  end

  def self.down
    remove_column :cards, :position
    remove_column :cards, :list_id
  end
end
