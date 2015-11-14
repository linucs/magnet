class AuthenticationProvider < ActiveRecord::Base
  has_many :user_authentications

  POLLING_INTERVAL = 10.minutes
  POLLING_TICKS = 5

  def self.instance(name)
    "providers/#{name}".classify.constantize
  end

  def instance
    AuthenticationProvider.instance(name)
  end

  def title
    ENV["#{name}_title"] || name.titleize
  end

  def needs_authentication?
    !features.to_s.index('A').nil?
  end

  def allows_sharing?
    !features.to_s.index('S').nil?
  end

  def allows_likes?
    !features.to_s.index('L').nil?
  end

  def allows_comments?
    !features.to_s.index('C').nil?
  end

  def allows_live_streaming?
    !features.to_s.index('X').nil?
  end
end
