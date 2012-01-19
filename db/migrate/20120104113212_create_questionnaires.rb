class CreateQuestionnaires < ActiveRecord::Migration
  def self.up
    create_table :questionnaires do |t|
      t.string :token, :null => false
      t.integer :subject_id, :null => false
      t.string :subject_type, :null => false
      t.boolean :ever_reported
      t.integer :old_status_code
      t.integer :new_status_code
      t.datetime :sent_at
      t.datetime :completed_at
      t.integer :user_id, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :questionnaires
  end
end
