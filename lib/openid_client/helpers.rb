module OpenidClient
  module Helpers
    USER_KEY = 'warden.user.user.key'

    protected

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def update_authentication
      timestamp = oid_get_timestamp
      state = oid_load_state

      oid_info "server timestamp = #{timestamp}"
      oid_info "client timestamp = #{state['timestamp']}"

      if not session[:openid_checked].blank?
        oid_info "finished re-authentication"
        oid_save_state 'timestamp' => timestamp
        session[:openid_checked] = nil

        old_session = oid_decoded(state['session'] || {})
        if session[USER_KEY] == old_session[USER_KEY]
          oid_info "Restoring previous session"
          old_session.each { |k, v| session[k] = v }
        end

        target = state['request_target']
        if target.blank?
          oid_info "no redirection required"
        elsif target['_method'].nil?
          oid_info "redirecting to requested page #{target}"
        else
          oid_info "resubmitting request"
        end
      elsif oid_recheck_needed?(timestamp, state)
        oid_info "starting re-authentication"
        oid_save_state('request_target' => oid_target_hash,
                       'session' => oid_encoded(session),
                       'timestamp' => nil)
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
      cookies.signed[OpenidClient::Config.client_state_key] = {
        :value => state.to_json,
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

    def oid_recheck_needed?(timestamp, state)
      due       = state['timestamp'] != timestamp
      relevant  = (timestamp != 'x' or not session[USER_KEY].blank?)
      recursive = (
        params[:controller] == OpenidClient::Config.session_controller_name and
        ['new', 'create', 'destroy'].include? params[:action])

      due and relevant and not recursive
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
        "#{url}?#{t.to_params}"
      end
    end
  end
end
