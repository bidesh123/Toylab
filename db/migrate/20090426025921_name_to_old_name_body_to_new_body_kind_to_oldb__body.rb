class NameToOldNameBodyToNewBodyKindToOldb_body < ActiveRecord::Migration
  def self.up
    rename_column :cards, :kind, :old_body
    rename_column :cards, :name, :old_name
    rename_column :cards, :body, :new_body
  end

  def self.down
    rename_column :cards, :old_body, :kind
    rename_column :cards, :old_name, :name
    rename_column :cards, :new_body, :body
  end
end
