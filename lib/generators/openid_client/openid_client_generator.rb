require 'rails/generators'
require 'rails/generators/migration'

class OpenidClientGenerator < Rails::Generators::Base
  include Rails::Generators::Migration

   # http://github.com/rails/rails/blob/master/activerecord/lib/generators/active_record.rb
  def self.next_migration_number(dirname) #:nodoc:
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  def create_migration_file
    migration_template '../../templates/migration.rb', 'db/migrate/create_openid_users_table.rb'
  end
end
