require 'openid_client'
require 'rails'
require 'rack'


module Rack
  class MethodOverrideExtended < Rack::MethodOverride
    def initialize(app)
      @app = app
    end

    def call(env)
      req = Request.new(env)
      method = req.params[METHOD_OVERRIDE_PARAM_KEY] ||
        env[HTTP_METHOD_OVERRIDE_HEADER]
      method = method.to_s.upcase
      if HTTP_METHODS.include?(method)
        env['rack.methodoverride.original_method'] = env['REQUEST_METHOD']
        env['REQUEST_METHOD'] = method
      end

      @app.call(env)
    end
  end
end

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
    initializer 'openid_client.add_middleware' do |app|
      app.middleware.insert_before Warden::Manager, Rack::OpenID
      app.middleware.swap Rack::MethodOverride, Rack::MethodOverrideExtended
    end
  end
end
