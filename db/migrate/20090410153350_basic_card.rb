class BasicCard < ActiveRecord::Migration
  def self.up
    create_table :cards do |t|
      t.string   :name
      t.text     :body
      t.datetime :created_at
      t.datetime :updated_at
    end
  end

  def self.down
    drop_table :cards
  end
end
