Rails.application.routes.draw do
  devise_for :openid_users, :controllers => { :sessions => 'openid_sessions' }
end
