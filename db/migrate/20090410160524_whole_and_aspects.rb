class WholeAndAspects < ActiveRecord::Migration
  def self.up
    add_column :cards, :whole_id, :integer
  end

  def self.down
    remove_column :cards, :whole_id
  end
end
