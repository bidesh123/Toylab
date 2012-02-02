class AddCategoryToCards < ActiveRecord::Migration
  def self.up
    add_column :cards, :category, :string
  end

  def self.down
    remove_column :cards, :category
  end
end
