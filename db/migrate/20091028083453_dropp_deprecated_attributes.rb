class DroppDeprecatedAttributes < ActiveRecord::Migration
  def self.up
    remove_column :cards, :context_id
  end

  def self.down
    add_column :cards, :context_id, :integer
  end
end
