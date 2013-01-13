class CreatePhotoInformations < ActiveRecord::Migration
  def change
    create_table :photo_informations do |t|
      t.integer :photo_id
      t.binary :thumbnail
      t.integer :roll_id, :null => false
      t.integer :album_id
      t.text :exif_data
      
      t.timestamps
    end
  end
end
