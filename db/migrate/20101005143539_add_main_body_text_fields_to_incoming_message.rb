class AddMainBodyTextFieldsToIncomingMessage < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :main_body_text, :text
    add_column :incoming_messages, :main_body_text_folded, :text
  end

  def self.down
    remove_column :incoming_messages, :main_body_text_folded
    remove_column :incoming_messages, :main_body_text
  end
end
