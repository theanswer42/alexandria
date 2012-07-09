# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120706063751) do

  create_table "albums", :force => true do |t|
    t.string   "name",       :null => false
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "exif_data", :force => true do |t|
    t.integer  "photo_id",   :null => false
    t.text     "exif_data"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "photos", :force => true do |t|
    t.string   "filename",    :limit => 2048, :null => false
    t.binary   "thumbnail"
    t.string   "checksum",    :limit => 1024, :null => false
    t.string   "name",        :limit => 1024
    t.string   "description", :limit => 4096
    t.datetime "timestamp",                   :null => false
    t.integer  "imported_at",                 :null => false
    t.integer  "roll_id",                     :null => false
    t.integer  "album_id"
    t.datetime "created_at",                  :null => false
    t.datetime "updated_at",                  :null => false
  end

  add_index "photos", ["checksum"], :name => "index_photos_on_checksum", :length => {"checksum"=>767}

  create_table "rolls", :force => true do |t|
    t.string   "name",        :limit => 256, :null => false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at",                 :null => false
    t.datetime "updated_at",                 :null => false
  end

  create_table "taggings", :force => true do |t|
    t.integer  "tag_id"
    t.integer  "taggable_id"
    t.string   "taggable_type"
    t.integer  "tagger_id"
    t.string   "tagger_type"
    t.string   "context",       :limit => 128
    t.datetime "created_at"
  end

  add_index "taggings", ["tag_id"], :name => "index_taggings_on_tag_id"
  add_index "taggings", ["taggable_id", "taggable_type", "context"], :name => "index_taggings_on_taggable_id_and_taggable_type_and_context"

  create_table "tags", :force => true do |t|
    t.string "name"
  end

end
