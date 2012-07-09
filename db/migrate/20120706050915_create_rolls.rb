class CreateRolls < ActiveRecord::Migration
  def change
    create_table :rolls do |t|
      t.string :name, :limit => 256, :null => false
      
      t.datetime :started_at
      t.datetime :finished_at
      
      t.timestamps
    end
  end
end
