class AddLooksLikeToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :look_like_id, :integer
  end

  def self.down
    remove_column :cards, :look_like_id
  end
end
