class BasedOnBecomesMold < ActiveRecord::Migration
  def self.up
    rename_column :cards, :based_on_id, :mold_id
  end

  def self.down
    rename_column :cards, :mold_id, :based_on_id
  end
end
