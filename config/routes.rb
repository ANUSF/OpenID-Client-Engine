Rails.application.routes.draw do
  match 'openid/sign_in' => 'openid_client/sessions#new'
  match 'openid/sign_in' => 'openid_client/sessions#create', :via => 'post'
  match 'openid/sign_out' => 'openid_client/sessions#destroy'
end
