class RenameSubdomainToKey < ActiveRecord::Migration
  def self.up
    rename_column :campaigns, :subdomain, :key
  end

  def self.down
  end
end
