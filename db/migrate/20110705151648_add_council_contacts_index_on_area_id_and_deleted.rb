class AddCouncilContactsIndexOnAreaIdAndDeleted < ActiveRecord::Migration
  def self.up
    add_index :council_contacts, [:area_id, :deleted], :name => 'index_council_contacts_on_area_id_and_deleted'
  end

  def self.down
    remove_index :council_contacts, "area_id_and_deleted"
  end
end
