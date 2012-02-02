class AddPreferredViewField < ActiveRecord::Migration
  def self.up
    add_column :cards, :view, :string
  end

  def self.down
    remove_column :cards, :view
  end
end
