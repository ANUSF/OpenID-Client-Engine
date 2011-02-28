require 'rails/generators'
require 'rails/generators/migration'

class OpenidClientGenerator < Rails::Generators::NamedBase
  include Rails::Generators::Migration

  source_root File.expand_path '../../templates', __FILE__

  # From Rails sources: activerecord/lib/generators/active_record.rb
  def self.next_migration_number(dirname) #:nodoc:
    if ActiveRecord::Base.timestamped_migrations
      Time.now.utc.strftime("%Y%m%d%H%M%S")
    else
      "%.3d" % (current_migration_number(dirname) + 1)
    end
  end

  def controller_name
    "#{singular_name}_sessions"
  end

  def create_migration_file
    migration_template 'migration.rb', "db/migrate/create_#{file_name}_table.rb"
  end

  def create_model
    template 'model.rb', "app/models/#{file_name}.rb"
  end

  def create_controller
    template 'controller.rb', "app/controllers/#{controller_name}_controller.rb"
  end

  def create_view
    copy_file 'sign_in.html.erb', "app/views/#{controller_name}/new.html.erb"
  end

  def create_routes
    route "devise_for :#{plural_name}, " +
      ":controllers => { :sessions => '#{controller_name}' }"
  end

  def create_locale
    template 'locale.en.yml',
             "config/locales/devise_#{singular_name}_sessions.en.yml"
  end
end
