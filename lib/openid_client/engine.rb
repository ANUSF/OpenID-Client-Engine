require "openid_client"
require "rails"

module OpenidClient
  class Config
    class << self
      # --- To add configuration options, we can do something like this:

      # attr_accessor :server_url, :fallback_layer

      # server_url = "http://vmap0.tiles.osgeo.org/wms/vmap0"
      # fallback_layer = 'basic'
    end
  end

  class Engine < Rails::Engine
    initializer "openid_client.add_middleware" do |app|
      app.middleware.insert_before(Warden::Manager, Rack::OpenID)
    end
  end
end
