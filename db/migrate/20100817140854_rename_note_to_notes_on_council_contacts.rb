class RenameNoteToNotesOnCouncilContacts < ActiveRecord::Migration
  def self.up
    rename_column :council_contacts, :note, :notes
  end

  def self.down
    rename_column :council_contacts, :notes, :note
  end
end
