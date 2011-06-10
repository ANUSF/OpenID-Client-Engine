module OpenidClient
  module Helpers

    protected

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def update_authentication
      state = load_oid_state
      Rails.logger.error "@@@ oid_state = #{state.inspect}"
      if openid_current?(state)
        unless state['request_url'].blank?
          request_url = state['request_url']
          state['request_url'] = nil
          save_oid_state state
          redirect_to request_url
        end
      elsif state['checking'].blank?
        state['request_url'] = request.url
        state['checking'] = true
        reset_session
        save_oid_state state
        redirect_to new_user_session_path(:user => { :immediate => true })
      else
        save_oid_state state
      end
    end

    def openid_current?(state)
      if not session[:openid_checked].blank?
        state['checking'] = nil
        timestamp = cookies[OpenidClient::Config.server_timestamp_key]
        if timestamp.blank? or timestamp == state['server_timestamp']
          true
        else
          state['server_timestamp'] = timestamp
          session[:openid_checked] = nil
          false
        end
      else
        false
      end
    end

    def load_oid_state
      JSON::load(cookies.signed[OpenidClient::Config.client_state_key] || '{}')
    end

    def save_oid_state(state)
      cookies.signed[OpenidClient::Config.client_state_key] = state.to_json
    end
  end
end
