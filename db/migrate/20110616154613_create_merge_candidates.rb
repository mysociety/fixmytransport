class CreateMergeCandidates < ActiveRecord::Migration
  def self.up
    create_table :merge_candidates do |t|
      t.integer :national_route_id
      t.string :regional_route_ids
      t.boolean :is_same
    end
  end

  def self.down
    drop_table :merge_candidates
  end
end
