class AddOrganizationPersistentIdToResponsibilities < ActiveRecord::Migration
  def self.up
    add_column :responsibilities, :organization_persistent_id, :integer
  end

  def self.down
    remove_column :responsibilities, :organization_persistent_id
  end
end
