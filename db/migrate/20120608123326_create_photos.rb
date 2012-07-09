class CreatePhotos < ActiveRecord::Migration
  def change
    create_table :photos do |t|
      t.string :filename, :limit => 2048, :null => false
      t.binary :thumbnail, :limit => 10.kilobytes
      t.string :checksum, :limit => 1024, :null => false
      t.string :name, :limit => 1024
      t.string :description, :limit => 4096
      t.datetime :timestamp, :null => false
      t.integer :imported_at, :null => false
      t.integer :roll_id, :null => false
      t.integer :album_id
      
      t.timestamps
    end
    
    add_index :photos, :checksum
  end
end
