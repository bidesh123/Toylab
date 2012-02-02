class Instances < ActiveRecord::Migration
  def self.up
    rename_column :cards, :look_like_id, :based_on_id
    remove_column :cards, :based_on
  end

  def self.down
    rename_column :cards, :based_on_id, :look_like_id
    add_column :cards, :based_on, :string
  end
end
