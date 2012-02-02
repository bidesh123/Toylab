class AddOwnerIdToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :owner_id, :integer
  end

  def self.down
    remove_column :cards, :owner_id
  end
end
