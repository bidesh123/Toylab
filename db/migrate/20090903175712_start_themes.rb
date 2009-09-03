class StartThemes < ActiveRecord::Migration
  def self.up
    rename_column :cards, :category, :based_on
    add_column :cards, :theme, :string
  end

  def self.down
    rename_column :cards, :based_on, :category
    remove_column :cards, :theme
  end
end
