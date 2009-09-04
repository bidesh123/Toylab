class AddScript < ActiveRecord::Migration
  def self.up
    add_column :cards, :script, :text
  end

  def self.down
    remove_column :cards, :script
  end
end
