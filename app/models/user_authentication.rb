class UserAuthentication < ActiveRecord::Base
  belongs_to :user
  belongs_to :authentication_provider

  serialize :params

  def self.create_from_omniauth(params, user, provider)
    token_expires_at = params['credentials']['expires_at'] ? Time.at(params['credentials']['expires_at']).to_datetime : nil

    create(
      user: user,
      authentication_provider: provider,
      uid: params['uid'],
      token: params['credentials']['token'],
      token_secret: params['credentials']['secret'],
      token_expires_at: token_expires_at,
      params: params
    )
  end

  def token_expired?(t = Time.now)
    token_expires_at && token_expires_at < t
  end

  def refresh_token!(t = Time.now)
    if token_expired?(t)
      case authentication_provider.name
      when 'facebook'
        oauth = Koala::Facebook::OAuth.new(Figaro.env.facebook_app_id, Figaro.env.facebook_app_secret)
        token_info = oauth.exchange_access_token_info(token)
        update_attributes(token: token_info['access_token'], token_expires_at: Time.now + token_info['expires'].to_i.seconds)
      end
    end
  end
end
