class DeviseCreateUsers < ActiveRecord::Migration
  def self.up
    create_table :openid_users do |t|
      t.openid_authenticatable
      t.string :name
      t.string :email
    end

    add_index :openid_users, :identity_url, :unique => true
  end

  def self.down
    drop_table :openid_users
  end
end
