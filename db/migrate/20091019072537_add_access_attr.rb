class AddAccessAttr < ActiveRecord::Migration
  def self.up
    add_column :cards, :access, :string
  end

  def self.down
    remove_column :cards, :access
  end
end
