class BackToNameBodyKind < ActiveRecord::Migration
  def self.up
    rename_column :cards, :new_body, :body
    rename_column :cards, :old_name, :kind
    rename_column :cards, :old_body, :name
  end

  def self.down
    rename_column :cards, :body, :new_body
    rename_column :cards, :kind, :old_name
    rename_column :cards, :name, :old_body
  end
end
