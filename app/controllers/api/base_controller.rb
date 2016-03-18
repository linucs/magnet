class API::BaseController < ApplicationController
  include CleanPagination

  before_action :authenticate_user_from_token!

  def track_event(category, action, label = nil, value = nil)
    return unless Figaro.env.enable_google_analytics.to_b

    code = @board && @board.options.google_analytics_code.present? ? @board.options.google_analytics_code : Figaro.env.google_analytics_code
    domain = @board && @board.options.google_analytics_domain.present? ? @board.options.google_analytics_domain : Figaro.env.google_analytics_domain
    GoogleAnalyticsWorker.perform_async(code,
                                        domain: domain,
                                        remote_ip: request.remote_ip,
                                        user_agent: request.user_agent,
                                        referer: request.referer,
                                        category: category,
                                        action: action,
                                        label: label,
                                        value: value,
                                        time: @start_time ? ((Time.now - @start_time) * 1000).to_i : nil)
  end

  private

  def authenticate_user_from_token!
    @start_time = Time.now
    user = authenticate_with_http_token { |t, _o| User.find_by_authentication_token(t) if t.present? }
    token = request.headers['X-API-KEY'] || params[:api_key] || params[:user_token]
    user ||= User.find_by_authentication_token(token) if token.present?

    if user
      request.env['devise.skip_trackable'] = true
      sign_in user, store: false
    else
      request_http_token_authentication
    end
  end
end
