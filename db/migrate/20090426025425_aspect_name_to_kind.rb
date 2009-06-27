class AspectNameToKind < ActiveRecord::Migration
  def self.up
    rename_column :cards, :aspect_name, :kind
  end

  def self.down
    rename_column :cards, :kind, :aspect_name
  end
end
