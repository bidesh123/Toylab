class FirstTryAtPad < ActiveRecord::Migration
  def self.up
    add_column :cards, :pad, :boolean
    remove_column :cards, :number
  end

  def self.down
    remove_column :cards, :pad
    add_column :cards, :number, :integer
  end
end
