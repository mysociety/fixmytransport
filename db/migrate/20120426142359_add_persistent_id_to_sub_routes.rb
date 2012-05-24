class AddPersistentIdToSubRoutes < ActiveRecord::Migration
  def self.up
    add_column :sub_routes, :persistent_id, :integer
    add_index :sub_routes, :persistent_id
    execute("ALTER TABLE sub_routes
             ALTER COLUMN persistent_id
             SET DEFAULT currval('sub_routes_id_seq')")
  end

  def self.down
    remove_column :sub_routes, :persistent_id
    execute("ALTER TABLE sub_routes
             ALTER COLUMN persistent_id
             DROP DEFAULT")
  end
end
