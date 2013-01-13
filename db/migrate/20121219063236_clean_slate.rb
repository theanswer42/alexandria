class CleanSlate < ActiveRecord::Migration
  def up
    drop_table :exif_data
    drop_table :photos
  end

  def down
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
  end
end
