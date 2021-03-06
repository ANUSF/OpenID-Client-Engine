class OpenidClient::SessionsController < Devise::SessionsController
  helper_method :default_login, :default_logout, :server_human_name

  def new
    create if force_default?
  end

  def create
    login = (params[resource_name] ||= {})[:identity_url]

    params[resource_name][:identity_url] = normalised_identity_url login
    resource = warden.authenticate!(:scope => resource_name, :recall => recall)

    session[:openid_checked] = true
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
    
    if back_to_root
      if (params[resource_name] || {})[:immediate]
        session[:openid_checked] = true
      end
      redirect_to root_url
    end
  end

  protected

  def force_default?
    false
  end

  def default_login
    OpenidClient::Config.default_login
  end

  def identity_url_for_user(user)
    "#{default_login}/user/#{user}"
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

  def normalised_identity_url(url)
    if url.blank?
      default_login
    elsif url =~ /\A[\w\.-_]*\z/
      identity_url_for_user url
    else
      url
    end
  end
end
