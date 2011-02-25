class <%= controller_name.camelize %>Controller < Devise::SessionsController
  SERVER = 'http://openid.assda.edu.au/joid'

  def create
    login = params[resource_name][:identity_url]

    # -- allow users to log in with just their ASSDA names
    unless login.starts_with?('http://')
      login = params[resource_name][:identity_url] = "#{SERVER}/user/#{login}"
    end

    if bypass_openid
      resource_class = resource_name.to_s.classify.constantize
      resource = resource_class.find_or_create_by_identity_url(login)
    else
      resource = warden.authenticate!(:scope => resource_name, :recall => "new")
    end

    set_flash_message :notice, :signed_in
    sign_in_and_redirect(resource_name, resource)
  end

  def destroy
    if signed_in?(resource_name)
      id_url = warden.authenticate(:scope => resource_name)
      set_flash_message :notice, :signed_out
    end

    sign_out(resource_name)

    if bypass_openid or params[:on_server].blank?
      redirect_to root_url
    else
      # -- log out from OpenID provider (not part of the OpenID protocol)
      server = id_url.blank? ? SERVER : id_url.sub(/\/user\/[^\/]*$/, '')
      logout_ext = (server == SERVER) ? '.jsp' : ''
      back = URI.escape(root_url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))

      redirect_to "#{server}/logout#{logout_ext}?return_url=#{back}"
    end
  end

  private

  # Whether to bypass OpenID verification.
  def bypass_openid
    [
     #'development',
     'test',
     'cucumber'
    ].include?(Rails.env)
  end
end
