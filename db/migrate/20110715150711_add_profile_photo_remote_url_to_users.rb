class AddProfilePhotoRemoteUrlToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :profile_photo_remote_url, :string
  end

  def self.down
    remove_column :users, :profile_photo_remote_url
  end
end
