A Rails engine implementing a simple OpenID client with some
customisation. All the heavy lifting is done by devise, ruby-openid
and rack-openid.

Installation
------------

1) Create a new rails application:

    rails new oid-test

2) Add these lines to your Gemfile:

    gem 'devise'
    gem 'devise_openid_authenticatable'
    gem 'openid_client', :git => 'git://github.com/ANUSF/OpenID-Client-Engine.git'

    gem 'mongrel', '~> 1.2.0.pre2'

We use mongrel here because WEBrick under MRI cannot handle long URLs.

3) Bundle:

    bundle

4) Set up devise:

    rails g devise:install

5) Run the generator for each user model:

    rails g openid_client user

6) Migrate the database:

    rake db:migrate

7) Make sure there is a `root_path` that devise can redirect to after sign-in.


Usage
-----

Most of the devise documentation should still apply. There are some
OpenID-specific extras built into the session controllers:

1) If no identity URL is specified by the user and `default_login`
returns a non-blank string, that string is used as the URL to
authenticate with. It should point to an OpenID provider's IDP service
(allowing login without a username being passed as part of the
identity URL). The default is 'http://myopenid.com'.

If moreover `force_default?` returns true, the local sign-in form is
bypassed completely and the user is sent to the default URL straight
away.

2) The method `identity_url_for_user` constructs a server-specific URL
from a user name. By default, if the server (default login) is
`http://guide.galaxy.net` and the user name is `arthur.dent`, the
identity URL constructed is
`http://guide.galaxy.net/user/arthur.dent`. By overriding the method,
other conventions can be implemented.

3) If on logout, `logout_url_for` returns a non-empty string when
applied to the current identity URL, that string is used as the URL to
redirect to for server-side logout. Otherwise, the user is simply
reminded to log out from the OpenID server manually.


Customisation
-------------

For each user model, the generator creates a controller which inherits
from `OpenidClient::SessionsController`. That controller can override
the protected methods `default_login`, `logout_url_for` and
`server_human_name` (a human-readable name for the default OpenID
provider that is used in the view) in order to change the default
behaviour.

The global defaults can be changed by setting the attributes
`default_login` and `server_human_name` in `OpenidClient::Config`.


Automatic re-authentication with the server
-------------------------------------------

An experimental new feature has been added that allows clients to
update their authentication status automatically when users log in or
out of the OpenID server. For this to work, the server must maintain a
cookie '_openid_session_timestamp' that gets changed after each such
event. Then the client application will automatically re-authenticate
with the server whenever the cookie value changes by including the
following code into the application controller:

    include OpenidClient::Helpers
    before_filter :oid_update_authentication

In order to prevent problems due to stale cookies, re-authentication
is automatically initiated after a configurable amount of time
(default 15 minutes) even when the server timestamp has not changed.

CAVEAT: at the moment, multiple user models or models named anything
other than 'user' are not supported with this feature.

The `OpenidClient::Helpers` module also provides a method
`oid_authentication_state` which does not perform any redirections but simply
returns a hash. Most of the entries are used internally by
`oid_update_authentication`, but the following can be useful within
controllers:

    :is_current # true if client session is still considered up-to-date
    :logged_in  # true if someone is currently logged in on the client


Configuration Example
---------------------

The code below configures the engine with the default values:

  OpenidClient::Config.configure do |c|
    # Default identity URL.
    c.default_login         = 'http://myopenid.com'

    # Displayed text for default OpenID server.
    c.server_human_name     = nil

    # Cookie name used by server to hold timestamp.
    c.server_timestamp_key  = :_openid_session_timestamp

    # Cookie name to store internal state in.
    c.client_state_key      = :_openid_client_state

    # Time after which re-authentication is forced.
    c.re_authenticate_after = 15.minutes
  end


Licencing
---------

Author: Olaf Delgado-Friedrichs (odf@github.com)

Copyright (c) 2011 The Australian National University

This software is being made available under the MIT licence.
