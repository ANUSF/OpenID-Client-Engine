module OpenidClient
  module Helpers
    USER_KEY = 'warden.user.user.key'

    protected

    def oid_authentication_state
      unless defined? @oid_authentication_state
        state            = oid_load_state

        server_timestamp = oid_get_timestamp
        client_timestamp = state['timestamp']
        logged_in        = session[USER_KEY].present?

        up_to_date = server_timestamp == client_timestamp
        irrelevant = !logged_in && server_timestamp == 'x'
        recursive  =
          params[:controller] == OpenidClient::Config.session_controller_name &&
          ['new', 'create', 'destroy'].include?(params[:action])
        is_current = up_to_date || irrelevant || recursive

        openid_checked   = session[:openid_checked].present?
        saved_target     = state['request_target']
        saved_session    = oid_decoded(state['session'] || {})
        same_user        = session[USER_KEY] == saved_session[USER_KEY]
        
        @oid_authentication_state = {
          :server_timestamp => server_timestamp,
          :client_timestamp => client_timestamp,
          :logged_in        => logged_in,
          :is_current       => is_current,

          :openid_checked   => openid_checked,
          :same_user        => same_user,
          :saved_target     => saved_target,
          :saved_session    => saved_session
        }
      end
      @oid_authentication_state
    end

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def oid_update_authentication
      state = oid_authentication_state

      oid_info "server timestamp = #{state[:server_timestamp]}"
      oid_info "client timestamp = #{state[:client_timestamp]}"

      if state[:openid_checked]
        oid_info "finished (re-)authentication"
        oid_save_state 'timestamp' => state[:server_timestamp]
        session[:openid_checked] = nil

        if state[:same_user] and state[:saved_session].present?
          reset_session
          oid_info "Restoring previous session"
          state[:saved_session].each { |k, v| session[k] = v }
        end

        target = state[:saved_target]
        if target.blank?
          oid_info "no redirection required"
        elsif target['_method'].nil?
          oid_info "redirecting to requested page #{target}"
        else
          oid_info "resubmitting request"
        end
      elsif not state[:is_current]
        oid_info "starting re-authentication"
        oid_save_state('request_target' => oid_target_hash,
                       'session'        => oid_encoded(session),
                       'timestamp'      => nil)
        reset_session
        target = new_user_session_path :user => { :immediate => true }
      else
        oid_info "proceeding normally"
      end

      redirect_to target unless target.blank?
    end

    private

    def oid_info(s)
      Rails.logger.info "OID check: #{s}"
    end

    def oid_load_state
      JSON::load(cookies.signed[OpenidClient::Config.client_state_key] || '{}')
    end

    def oid_save_state(state)
      state_encoded = state.to_json
      unless Rails.env.production?
        oid_info "encoded state size = #{state_encoded.size}"
        oid_info "state contents: #{state.inspect}"
      end

      cookies.signed[OpenidClient::Config.client_state_key] = {
        :value => state_encoded,
        :expires => OpenidClient::Config.re_authenticate_after.from_now
      }
    end

    def oid_encoded(source)
      result = {}
      source.each { |k, v| result[k] = Marshal.dump(v) }
      result
    end

    def oid_decoded(source)
      result = {}
      source.each { |k, v| result[k] = Marshal.load(v) }
      result
    end

    def oid_get_timestamp
      t = cookies[OpenidClient::Config.server_timestamp_key]
      if t.blank? then 'x' else t end
    end

    def oid_target_hash
      t = if request.request_method != 'GET'
            request.parameters.merge({ :_method => request.request_method })
          else
            request.parameters.merge({})
          end
      t.delete :action
      t.delete :controller
      url = url_for request.path_parameters
      full_url = url_for request.parameters
      if full_url == url
        url
      else
        "#{url}?#{t.to_param}"
      end
    end
  end
end
