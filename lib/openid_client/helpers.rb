module OpenidClient
  module Helpers
    USER_KEY = 'warden.user.user.key'

    protected

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def update_authentication
      timestamp = get_timestamp
      state = load_oid_state

      info "server timestamp = #{timestamp}"
      info "client timestamp = #{state['timestamp']}"

      if not session[:openid_checked].blank?
        info "finished re-authentication"
        save_oid_state 'timestamp' => timestamp
        session[:openid_checked] = nil

        old_session = state['session'] || {}
        if session[USER_KEY] == old_session[USER_KEY]
          info "Restoring previous session"
          old_session.each { |k,v| session[k] = v unless k == "flash" }
          (old_session['flash'] || []).each { |x| flash[x[0]] = x[1] }
        end

        target = state['request_target']
        if target.blank?
          info "no redirection required"
        elsif target['_method'].nil?
          info "redirecting to requested page #{target}"
        else
          info "resubmitting request"
        end
      elsif recheck_needed(timestamp, state)
        info "starting re-authentication"
        save_oid_state('request_target' => target_hash,
                       'session' => session,
                       'timestamp' => nil)
        reset_session
        target = new_user_session_path :user => { :immediate => true }
      else
        info "proceeding normally"
      end

      redirect_to target unless target.blank?
    end

    private

    def info(s)
      Rails.logger.info "OID check: #{s}"
    end

    def load_oid_state
      JSON::load(cookies.signed[OpenidClient::Config.client_state_key] || '{}')
    end

    def save_oid_state(state)
      cookies.signed[OpenidClient::Config.client_state_key] = {
        :value => state.to_json,
        :expires => OpenidClient::Config.re_authenticate_after.from_now
      }
    end

    def get_timestamp
      t = cookies[OpenidClient::Config.server_timestamp_key]
      if t.blank? then 'x' else t end
    end

    def recheck_needed(timestamp, state)
      state['timestamp'] != timestamp and 
        (params[:controller] != OpenidClient::Config.session_controller_name or
         not ['new', 'create', 'destroy'].include? params[:action])
    end

    def target_hash
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
        "#{url}?#{t.to_params}"
      end
    end
  end
end
