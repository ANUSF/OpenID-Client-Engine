module OpenidClient
  module Helpers

    protected

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def update_authentication
      key = OpenidClient::Config.server_timestamp_key
      timestamp = cookies[key]
      cookies[key] = timestamp = 'x' if timestamp.blank?
      Rails.logger.error "@@@ server timestamp = #{timestamp}"

      state = load_oid_state
      Rails.logger.error "@@@ initial state = #{state.inspect}"

      if not session[:openid_checked].blank?
        save_oid_state 'request_url' => nil, 'finished' => timestamp
        session[:openid_checked] = nil
        target = state['request_url']
      elsif state['finished'] != timestamp and
          not request.path =~ /^#{new_user_session_path}\??/
        save_oid_state 'request_url' => request.url, 'finished' => nil
        reset_session
        target = new_user_session_path(:user => { :immediate => true })
      end

      Rails.logger.error "@@@ final state = #{load_oid_state.inspect}"
      redirect_to target unless target.blank?
    end

    def load_oid_state
      JSON::load(cookies.signed[OpenidClient::Config.client_state_key] || '{}')
    end

    def save_oid_state(state)
      cookies.signed[OpenidClient::Config.client_state_key] = state.to_json
    end
  end
end
