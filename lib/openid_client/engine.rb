require "openid_client"
require "rails"

module OpenidClient
  class Config
    class << self
      attr_accessor :default_login, :server_human_name,
                    :server_timestamp_key, :client_state_key

      def configure
        yield self if block_given?
      end
    end
  end

  OpenidClient::Config.configure do |c|
    c.default_login        = 'http://myopenid.com'
    c.server_timestamp_key = :_openid_session_timestamp
    c.client_state_key     = :_openid_client_state
  end

  class Engine < Rails::Engine
    initializer "openid_client.add_middleware" do |app|
      app.middleware.insert_before(Warden::Manager, Rack::OpenID)
    end
  end
end
