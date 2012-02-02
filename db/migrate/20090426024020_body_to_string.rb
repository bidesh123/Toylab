class BodyToString < ActiveRecord::Migration
  def self.up
    change_column :cards, :body, :string, :limit => 255
  end

  def self.down
    change_column :cards, :body, :text
  end
end
