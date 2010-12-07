class AddUserNameToCampaignComments < ActiveRecord::Migration
  def self.up
    add_column :campaign_comments, :user_name, :string
    add_column :campaign_comments, :confirmed_at, :datetime
    add_column :campaign_comments, :status_code, :integer
  end

  def self.down
    remove_column :campaign_comments, :user_name
    remove_column :campaign_comments, :confirmed_at
    remove_column :campaign_comments, :status_code
  end
end
