module OpenidClient
  module Helpers

    protected

    # Redirects to a requested page after authentication; checks whether
    # user is already authenticated against a single-sign-on server
    # otherwise. This would typically be used as a before filter.
    def update_authentication
      timestamp = get_timestamp
      info "server timestamp = #{timestamp}"

      state = load_oid_state
      info "initial state = #{state.inspect}"
      info "csrf token = #{form_authenticity_token}"

      if not session[:openid_checked].blank?
        info "finished re-authentication"
        save_oid_state 'finished' => timestamp
        session[:openid_checked] = nil

        target = state['request_target']
        if target.nil?
          info "no redirection required"
        elsif target['_method'].nil?
          info "redirecting to requested page"
        else
          info "resubmitting request"
          if state['user_key'] != session['warden.user.user.key']
            info "user key has changed from #{state['user_key']} " +
              "to #{session['warden.user.user.key']}"
          elsif not state['verified']
            info "request did not pass csrf validation"
          else
            info "updating authenticity token"
            target[request_forgery_protection_token.to_s] =
              form_authenticity_token
            #request.headers['X-CSRF-Token'] = form_authenticity_token
          end
        end
      elsif recheck_needed(timestamp, state)
        info "starting re-authentication"
        save_oid_state('request_target' => target_hash,
                       'user_key' => session['warden.user.user.key'],
                       'verified' => verified_request?,
                       'finished' => nil)
        reset_session
        target = new_user_session_path :user => { :immediate => true }
      end

      info "final state = #{load_oid_state.inspect}"
      info "target = #{target.inspect}"
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
        :expires => 15.seconds.from_now
        #:expires => 15.minutes.from_now
      }
    end

    def get_timestamp
      t = cookies[OpenidClient::Config.server_timestamp_key]
      if t.blank? then 'x' else t end
    end

    def recheck_needed(timestamp, state)
      state['finished'] != timestamp and 
        not request.path =~ /^#{new_user_session_path}\??/
    end

    def target_hash
      if request.request_method != 'GET'
        params.merge({ :_method => request.request_method })
      else
        params
      end
    end
  end
end
