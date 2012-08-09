class CreateExternalQuestionnaires < ActiveRecord::Migration
  def self.up
    create_table :external_questionnaires do |t|
      t.string :token, :null => false
      t.integer :subject_id, :null => false
      t.string :subject_type, :null => false
      t.string :questionnaire_code, :null => false
      t.timestamps
    end
  end

  def self.down
    drop_table :external_questionnaires
  end
end
