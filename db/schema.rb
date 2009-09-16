# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090915051232) do

  create_table "cards", :force => true do |t|
    t.string   "kind"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "whole_id"
    t.text     "body"
    t.integer  "number"
    t.integer  "list_id"
    t.string   "based_on"
    t.integer  "look_like_id"
    t.string   "theme"
    t.integer  "owner_id"
    t.text     "script"
    t.integer  "context_id"
    t.integer  "table_id"
  end

  create_table "users", :force => true do |t|
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "name"
    t.string   "email_address"
    t.boolean  "administrator",                           :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "state",                                   :default => "active"
    t.datetime "key_timestamp"
  end

end
