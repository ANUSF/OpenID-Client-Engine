class OpenidClient::SessionsController < Devise::SessionsController
  helper_method :default_login, :default_logout, :server_human_name

  def create
    login = params[resource_name][:identity_url]

    if bypass_openid?
      resource_class = resource_name.to_s.classify.constantize
      resource = resource_class.find_or_create_by_identity_url(login)
    else
      params[resource_name][:identity_url] = default_login if login.blank?
      resource = warden.authenticate!(:scope => resource_name, :recall => "new")
    end

    set_flash_message :notice, :signed_in
    sign_in_and_redirect(resource_name, resource)
  end

  def destroy
    set_flash_message :notice, :signed_out if signed_in?(resource_name)
    sign_out(resource_name)

    if bypass_openid? or params[:on_server].blank?
      redirect_to root_url
    elsif default_logout
      back = URI.escape(root_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      redirect_to "#{default_logout}?return_url=#{back}"
    end
  end

  protected

  def default_login
    OpenidClient::Config.default_login
  end

  def default_logout
    OpenidClient::Config.default_logout
  end

  def server_human_name
    OpenidClient::Config.server_human_name || default_login
  end

  # Whether to bypass OpenID verification.
  def bypass_openid?
    [ 'test', 'cucumber' ].include?(Rails.env)
  end
end