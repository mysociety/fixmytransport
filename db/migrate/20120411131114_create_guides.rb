class CreateGuides < ActiveRecord::Migration
  def self.up
    create_table :guides do |t|
      t.string :title, :null => false
      t.string :partial_name, :null => false
    end
    add_column :guides, :cached_slug, :string
    add_index  :guides, :cached_slug, :unique => true
  end

  def self.down
    drop_table :guides
  end
end
