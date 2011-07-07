class MakeCommentsAndUpdatesVisible < ActiveRecord::Migration
  def self.up
    execute "UPDATE campaign_events set visible = 't' where event_type in ('comment_added', 'campaign_update_added');"
  end

  def self.down
  end
end
