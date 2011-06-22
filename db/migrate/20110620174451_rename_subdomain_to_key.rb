class RenameSubdomainToKey < ActiveRecord::Migration
  def self.up
    rename_column :campaigns, :subdomain, :key
  end

  def self.down
    rename_column :campaigns, :key, :subdomain
  end
end
