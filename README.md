A Rails engine implementing a simple OpenID client with some
customisation. All the heavy lifting is done by devise, ruby-openid
and rack-openid.

Step by step:

1) Create a new rails application:

    rails new oid-test -J -T

2) Add these lines to Gemfile:

    gem 'mongrel', '~> 1.2.0.pre2'
    gem 'devise'
    gem 'devise_openid_authenticatable'
    gem 'openid_client', :git => 'git://github.com/ANUSF/OpenID-Client-Engine.git'

Remark: Instead of mongrel, any server that can handle long URLs is fine.

3) Bundle:

    bundle

4) Set up devise:

   rails g devise:install

5) Run the generator for each user model:

    rails g openid_client user

6) Migrate the database:

    rake db:migrate

7) Make sure there is a `root_path` that devise can redirect to after sign-in.


Author: Olaf Delgado-Friedrichs (odf@github.com)

Copyright (c) 2011 The Australian National University

This software is being made available under the MIT licence.
