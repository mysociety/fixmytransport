class AddSkipMissingEmailAlertFlag < ActiveRecord::Migration
  def self.up
      add_column :operators, :skip_missing_email_alert, :boolean, :null => false, :default => false
  end

  def self.down
      remove_column :operators, :skip_missing_email_alert
  end
end
