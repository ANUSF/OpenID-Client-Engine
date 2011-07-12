module OpenidClient
  module Helpers

    protected

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def update_authentication
      timestamp = get_timestamp
      Rails.logger.info "OID check: server timestamp = #{timestamp}"

      state = load_oid_state
      Rails.logger.info "OID check: initial state = #{state.inspect}"

      if not session[:openid_checked].blank?
        Rails.logger.info "OID check: finished (redirecting to requested page)"
        save_oid_state 'request_url' => nil, 'finished' => timestamp
        session[:openid_checked] = nil
        target = state['request_url']
      elsif state['finished'] != timestamp and
          not request.path =~ /^#{new_user_session_path}\??/
        Rails.logger.info "OID check: changes on server, re-authenticating"
        save_oid_state 'request_url' => request.url, 'finished' => nil
        reset_session
        target = new_user_session_path(:user => { :immediate => true })
      end

      Rails.logger.info "OID check: final state = #{load_oid_state.inspect}"
      redirect_to target unless target.blank?
    end

    def load_oid_state
      JSON::load(cookies.signed[OpenidClient::Config.client_state_key] || '{}')
    end

    def save_oid_state(state)
      cookies.signed[OpenidClient::Config.client_state_key] = state.to_json
    end

    def get_timestamp
      t = cookies[OpenidClient::Config.server_timestamp_key]
      if t.blank? then 'x' else t end
    end
  end
end
