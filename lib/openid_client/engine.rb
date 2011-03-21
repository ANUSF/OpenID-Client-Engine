require "openid_client"
require "rails"

module OpenidClient
  class Config
    class << self
      attr_accessor :default_login, :server_human_name
    end
  end

  class Engine < Rails::Engine
    initializer "openid_client.add_middleware" do |app|
      app.middleware.insert_before(Warden::Manager, Rack::OpenID)
    end

    initializer "openid_client.configure" do |app|
      OpenidClient::Config.default_login = 'http://myopenid.com'
    end
  end
end
