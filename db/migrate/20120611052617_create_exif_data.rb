class CreateExifData < ActiveRecord::Migration
  def change
    create_table :exif_data do |t|
      t.integer :photo_id, :null => false
      t.text :exif_data, :limit => 8192
      
      t.timestamps
    end
  end
end
