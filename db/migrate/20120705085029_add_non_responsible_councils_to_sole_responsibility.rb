class AddNonResponsibleCouncilsToSoleResponsibility < ActiveRecord::Migration
  def self.up
    add_column :sole_responsibilities, :non_responsible_council_id, :integer
  end

  def self.down
    remove_column :sole_responsibilities, :non_responsible_council_id
  end
end
