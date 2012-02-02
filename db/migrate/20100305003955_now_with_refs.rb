class NowWithRefs < ActiveRecord::Migration
  def self.up
    add_column :cards, :ref_id, :integer
  end

  def self.down
    remove_column :cards, :ref_id
  end
end
