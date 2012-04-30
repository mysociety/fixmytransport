class CreateGuideExamples < ActiveRecord::Migration

  def self.up
    create_table :campaigns_guides, :id => false do |t|
      t.integer :campaign_id
      t.integer :guide_id
    end
    create_table :guides_problems, :id => false do |t|
      t.integer :problem_id
      t.integer :guide_id
    end
  end

  def self.down
    drop_table :campaigns_guides
    drop_table :guides_problems
  end

end
