class Feed < ActiveRecord::Base
  belongs_to :board
  belongs_to :authentication_provider
  belongs_to :user

  before_destroy :cleanup_cards

  attr_accessor :user_authentication
  attr_accessor :board_name

  scope :polling, -> { where(polling: true) }
  scope :live_streaming, -> { where(live_streaming: true) }

  validates_presence_of :authentication_provider, :user
  validate :at_least_one_option_must_be_selected
  validate :maximum_number_of_enabled_feeds

  serialize :options

  paginates_per 10

  def user_authentication
    @user_authentication ||= UserAuthentication.find_by(user_id: user.id, authentication_provider_id: authentication_provider.id)
  end

  def token
    user_authentication.try(:token)
  end

  def token_secret
    user_authentication.try(:token_secret)
  end

  def refresh_token_if_expiring!
    user_authentication.try(:refresh_token!, Time.now + 1.day)
  rescue => e
    update_attribute(:enabled, false)
    Magnet.capture_exception(e, user: { email: user.to_s }, extra: { feed: name })
    NotificationMailer.token_expired(self).deliver_now
    raise
  end

  def name
    if self[:name].present?
      self[:name]
    elsif self[:options]
      self[:options].map do |k, v|
        if k.to_s.start_with? '_'
          nil
        elsif v == '1'
          option_label(k)
        else
          v.present? && v != '0' ? "#{option_label(k)}#{v}" : nil
        end
      end.compact.join(', ')
    end
  end

  def cards
    board.cards.where(feed_id: id)
  end

  def pollable?
    if user && !user.expired? && Feed.where(id: id, enabled: true, polling: false, live_streaming: false).update_all(polling: true, last_exception: nil) > 0
      reload
      true
    else
      false
    end
  end

  def poll(options = {})
    oldest = options[:oldest]
    foreground = options[:foreground]
    high_priority = options[:high_priority]
    if foreground
      Chewy.strategy(:atomic) do
        if authentication_provider.instance.poll(self, oldest)
          Rails.logger.info "Polled feed ##{self.id} with options: #{options}"
        end
      end
    else
      if high_priority
        FastPollWorker.perform_async(id, oldest)
      else
        SlowPollWorker.perform_async(id, oldest)
      end
    end
  end

  def streamable?
    if user && !user.expired? && Feed.where(id: id, enabled: true, polling: false, live_streaming: true).update_all(polling: true, last_exception: nil) > 0
      reload
      true
    else
      false
    end
  end

  def stream(options = {})
    foreground = options[:foreground]
    if foreground
      authentication_provider.instance.stream(self) do |client, tweet|
        block_given? ? yield(client, tweet) : true
      end
    else
      StreamingWorker.perform_async(id)
    end
  end

  def stop_streaming
    StreamingWorker.cancel!(id)
  end

  def options
    OpenStruct.new(self[:options])
  end

  def raw_options
    self[:options]
  end

  def option_label(key)
    I18n.t("feeds.options.#{key}")
  end

  def hashtags
    case provider_name
    when 'twitter'
      options.twitter_search.split(',')
    when 'instagram'
      options.tag_recent_media.split(',')
    when 'facebook'
      options.hashtags.split(',')
    when 'google_oauth2'
      [options.hashtag]
    when 'flickr'
      options.tags.split(',')
    end
  end

  def cleanup_cards
    FeedCleanupWorker.perform_async(board_id, id)
  end

  def self.restart_dead!
    polling.where('polled_at < ?', Time.now - AuthenticationProvider::POLLING_INTERVAL * AuthenticationProvider::POLLING_TICKS).update_all(polling: false)
  end

  def send_notification(msg, obj = self)
    WebsocketRails["board-#{board_id}"].trigger(msg, obj)
  end

  def handle_polling_exception(e)
    update_attribute(:last_exception, e.message)
    NotificationMailer.polling_exception(self, e).deliver_now if user.notify_exceptions?
  end

  private

  def at_least_one_option_must_be_selected
    if options.to_h.values.all? { |v| v.blank? || v == '0' }
      errors.add(:base, 'At least one option must be given')
    end
  end

  def maximum_number_of_enabled_feeds
    unless user_id.nil?
      max = User.find(user_id).max_feeds.to_i rescue 0
      if max > 0 && self.enabled? && Feed.joins(:board).where(user_id: user_id, enabled: true, boards: {hashtag: nil}).count >= max
        errors[:enabled] << I18n.t('activerecord.errors.models.feed.attributes.enabled.limit_reached', count: max)
      end
    end
  end
end
