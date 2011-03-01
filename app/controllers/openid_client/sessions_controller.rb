class OpenidClient::SessionsController < Devise::SessionsController
  LOGIN_URL  = 'http://myopenid.com'
  LOGOUT_URL = nil

  def create
    login = params[resource_name][:identity_url]

    if bypass_openid
      resource_class = resource_name.to_s.classify.constantize
      resource = resource_class.find_or_create_by_identity_url(login)
    else
      params[resource_name][:identity_url] = LOGIN_URL if login.blank?
      resource = warden.authenticate!(:scope => resource_name, :recall => "new")
    end

    set_flash_message :notice, :signed_in
    sign_in_and_redirect(resource_name, resource)
  end

  def destroy
    set_flash_message :notice, :signed_out if signed_in?(resource_name)
    sign_out(resource_name)

    if bypass_openid or params[:on_server].blank?
      redirect_to root_url
    elsif LOGOUT_URL
      back = URI.escape(root_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      redirect_to "#{LOGOUT_URL}?return_url=#{back}"
    end
  end

  private

  # Whether to bypass OpenID verification.
  def bypass_openid
    [ 'test', 'cucumber' ].include?(Rails.env)
  end
end
