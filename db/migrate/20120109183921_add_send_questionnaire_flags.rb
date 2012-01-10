class AddSendQuestionnaireFlags < ActiveRecord::Migration
  def self.up
    add_column :problems, :send_questionnaire, :boolean, :null => false, :default => true
    add_column :campaigns, :send_questionnaire, :boolean,  :null => false, :default => true
  end

  def self.down
    remove_column :problems, :send_questionnaire
    remove_column :campaigns, :send_questionnaire
  end
end
