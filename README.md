A Rails engine implementing a simple OpenID client with some
customisation. All the heavy lifting is done by devise, ruby-openid
and rack-openid.

Installation
------------

1) Create a new rails application:

    rails new oid-test

2) Add these lines to Gemfile:

    gem 'devise'
    gem 'devise_openid_authenticatable'
    gem 'openid_client', :git => 'git://github.com/ANUSF/OpenID-Client-Engine.git'

    gem 'mongrel', '~> 1.2.0.pre2'

We use mongrel here because WEBrick under MRI cannot handle long URLs.

3) Bundle:

    bundle

4) Set up devise:

    rails g devise:install

5) Run the generator for each user model you would like to add:

    rails g openid_client user

6) Migrate the database:

    rake db:migrate

7) Make sure there is a `root_path` that devise can redirect to after sign-in.


Usage
-----

Most of the devise documentation should still apply. There are some
OpenID-specific extras built into the session controllers:

1) If the method `bypass_openid?` returns true, users are signed in
without any authentication, which can be useful in development and
testing. By default, it disables OpenID only during testing.

2) If no OpenID URL is specified by the user and `default_login`
returns a non-blank string, that string is used as the URL to
authenticate at. In order for this to be useful, the URL should hold
an OpenID provider's IDP service (allowing login via OpenID through
that provider without a consumer-spcified username). The default is
'http://myopenid.com'.

If moreover `force_default?` returns true, the local sign-in form is
bypassed completely and the user is sent to the default URL straight
away.

3) If the parameter `on_server` is passed on sign-out and the method
`default_logout` returns a non-empty string, that string is used as a
logout URL to redirect to after signing the user out locally.  This
will of course have unexpected results if the user is using an
identity from a different provider, but currently no measures are
taken to prevent that.


Customisation
-------------

For each user model, the generator creates a controller which inherits
from `OpenidClient::SessionsController`. That controller can override
the protected methods `default_login`, `default_logout`,
`server_human_name` (a human-readable name for the default OpenID
provider that is used in the view) and `bypass_openid?` in order to
change the default behaviour.

The global defaults can changed by setting the attributes
`default_login`, `default_logout` and `server_human_name` in
`OpenidClient::Config`.

Example:

    OpenidClient::Config.default_login = 'http://myopenid.com'


Licencing
---------

Author: Olaf Delgado-Friedrichs (odf@github.com)

Copyright (c) 2011 The Australian National University

This software is being made available under the MIT licence.
