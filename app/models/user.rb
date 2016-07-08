class User < ActiveRecord::Base
  has_and_belongs_to_many :boards
  has_many :feeds, dependent: :nullify do
    def with_alerts
      @alerts ||= where('last_exception IS NOT NULL')
    end
  end
  belongs_to :team

  before_save :ensure_authentication_token

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def self.create_from_omniauth(params)
    attributes = {
      email: params['info']['email'],
      password: Devise.friendly_token
    }

    create(attributes)
  end

  has_many :authentications, class_name: 'UserAuthentication', dependent: :destroy
  has_many :authentication_providers, through: :authentications

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :omniauthable, :account_expireable

  WHITELISTED_ATTRIBUTES = [:notify_exceptions]

  def is_connected_to?(provider_name)
    authentications.joins(:authentication_provider).exists?(authentication_providers: { name: provider_name })
  end

  def cards_count(provider)
    boards.inject(0) { |sum, b| sum + b.all_cards.by_provider(provider).count }
  end

  def teammates
    User.where(team_id: team_id)
  end

  def can_search_for_hashtags?
    is_connected_to?('twitter') || is_connected_to?('instagram') || is_connected_to?('tumblr')
  end

  def to_s
    email
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.find_by(authentication_token: token)
    end
  end
end
