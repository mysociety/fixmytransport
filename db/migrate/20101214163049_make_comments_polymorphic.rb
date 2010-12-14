class MakeCommentsPolymorphic < ActiveRecord::Migration
  def self.up
    add_column :comments, :commented_type, :string
    add_column :comments, :commented_id, :integer
  end

  def self.down
    remove_column :comments, :commented_type
    remove_column :comments, :commented_id
  end
end
