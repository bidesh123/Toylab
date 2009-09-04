class AddContextId < ActiveRecord::Migration
  def self.up
    add_column :cards, :context_id, :integer
  end

  def self.down
    remove_column :cards, :context_id
  end
end
