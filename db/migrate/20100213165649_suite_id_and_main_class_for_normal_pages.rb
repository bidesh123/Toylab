class SuiteIdAndMainClassForNormalPages < ActiveRecord::Migration
  def self.up
    create_table :mains do |t|
      t.string   :name
      t.text     :body
      t.datetime :created_at
      t.datetime :updated_at
    end
    
    add_column :cards, :suite_id, :integer
  end

  def self.down
    remove_column :cards, :suite_id
    
    drop_table :mains
  end
end
