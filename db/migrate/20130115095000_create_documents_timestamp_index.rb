class CreateDocumentsTimestampIndex < ActiveRecord::Migration
  def up
    add_index :documents, [:timestamp]
  end

  def down
    remove_index :documents, [:timestamp]
  end
end
