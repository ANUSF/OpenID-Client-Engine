Gem::Specification.new do |s|
  s.name        = 'openid_client'
  s.version     = '0.1.8'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Olaf Delgado-Friedrichs', 'ANUSF']
  s.email       = ['olaf.delgado-friedrichs@anu.edu.au']
  s.homepage    = 'http://sf.anu.edu.au/~oxd900'
  s.required_rubygems_version = '>= 1.3.5'
  s.files        = Dir.glob('{app,lib,config}/**/*') + %w(MIT-LICENSE)
  s.require_path = 'lib'

  s.add_dependency 'devise'
  s.add_dependency 'devise_openid_authenticatable'

  s.summary     = 'A simple, customised OpenID client based on devise.'
  s.description = %q{
    A Rails engine implementing a simple OpenID client with some
    customisation. All the heavy lifting is done by devise,
    ruby-openid and rack-openid.
  }
end
