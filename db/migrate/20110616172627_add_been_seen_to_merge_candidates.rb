class AddBeenSeenToMergeCandidates < ActiveRecord::Migration
  def self.up
    add_column :merge_candidates, :been_seen, :boolean
  end

  def self.down
    remove_column :merge_candidates, :been_seen
  end
end
