class BodyToAspectName < ActiveRecord::Migration
  def self.up
    rename_column :cards, :body, :aspect_name
  end

  def self.down
    rename_column :cards, :aspect_name, :body
  end
end
