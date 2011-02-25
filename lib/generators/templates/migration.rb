class Create<%= class_name %>Table < ActiveRecord::Migration
  def self.up
    create_table :<%= table_name %> do |t|
      t.string :identity_url
      t.string :name
      t.string :email
    end

    add_index :<%= table_name %>, :identity_url, :unique => true
  end

  def self.down
    drop_table :<%= table_name %>
  end
end
