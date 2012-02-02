class PositionToNumber < ActiveRecord::Migration
  def self.up
    rename_column :cards, :position, :number
  end

  def self.down
    rename_column :cards, :number, :position
  end
end
