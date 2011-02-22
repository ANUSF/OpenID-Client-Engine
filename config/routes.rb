Rails.application.routes.draw do
  devise_for 'openid_client/users',
             :controllers => { :sessions => 'openid_client/sessions' }
end
