class RenameAccessTokenType < ActiveRecord::Migration
  def self.up
    rename_column :access_tokens, :type, :token_type
  end

  def self.down
    rename_column :access_tokens, :token_type, :type
  end
end
