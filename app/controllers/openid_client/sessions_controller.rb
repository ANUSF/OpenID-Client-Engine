class OpenidClient::SessionsController < Devise::SessionsController
  helper_method :default_login, :default_logout, :server_human_name

  def new
    create if force_default?
  end

  def create
    login = (params[resource_name] ||= {})[:identity_url]

    params[resource_name][:identity_url] = default_login if login.blank?
    resource = warden.authenticate!(:scope => resource_name, :recall => recall)

    set_flash_message :notice, :signed_in
    sign_in_and_redirect(resource_name, resource)
  end

  def destroy
    back_to_root = true

    if signed_in?(resource_name)
      logout = logout_url_for self.send("current_#{resource_name}").identity_url
      sign_out(resource_name)

      if not logout.blank?
        set_flash_message :notice, :signed_out
        back = URI.escape(root_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
        redirect_to "#{logout}?return_url=#{back}"
        back_to_root = false
      else
        flash[:alert] = "Remember to log out from your OpenID provider, as well."
      end
    end
    
    redirect_to root_url if back_to_root
  end

  protected

  def force_default?
    false
  end

  def default_login
    OpenidClient::Config.default_login
  end

  def logout_url_for(identity)
    nil
  end

  def server_human_name
    OpenidClient::Config.server_human_name || default_login
  end

  def recall
    action = force_default? ? 'destroy' : 'new'
    "#{controller_path}##{action}"
  end
end
