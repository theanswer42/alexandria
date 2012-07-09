class CreateAlbums < ActiveRecord::Migration
  def change
    create_table :albums do |t|
      t.string :name, :null => false
      
      t.timestamps
    end
  end
end
