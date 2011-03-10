class CreateLoadRunCompletion < ActiveRecord::Migration
  def self.up
    create_table :load_run_completions do |t|
      t.integer :transport_mode_id 
      t.integer :admin_area_id
      t.string :load_type
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :load_run_completions
  end
end
