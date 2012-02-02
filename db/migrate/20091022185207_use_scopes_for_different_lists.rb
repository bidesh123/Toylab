class UseScopesForDifferentLists < ActiveRecord::Migration
  def self.up
    add_column :cards, :list_position, :integer
    add_column :cards, :whole_position, :integer
    add_column :cards, :table_position, :integer
  end

  def self.down
    remove_column :cards, :list_position
    remove_column :cards, :whole_position
    remove_column :cards, :table_position
  end
end
