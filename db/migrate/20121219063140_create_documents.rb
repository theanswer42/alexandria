class CreateDocuments < ActiveRecord::Migration
  def change
    create_table :documents do |t|
      t.string :type, :limit => 32, :null => false, :default => "Document"
      t.string :filename, :limit => 2048, :null => false
      t.string :checksum, :limit => 1024, :null => false
      t.string :name, :limit => 1024
      t.string :description, :limit => 4096
      t.datetime :timestamp, :null => false
      t.timestamps
    end
    
    add_index :documents, [:checksum]
  end
end
