class AddArchiveInformation < ActiveRecord::Migration
  def up
    add_column :documents, :archive_id, :string
    add_column :documents, :archived_at, :datetime
  end
  
  def down
    remove_column :documents, :archive_id
    remove_column :documents, :archived_at
  end
end


