require 'rails_autolink/helpers'

class Providers::Twitter
  MAX_TWEETS = 50

  class Client
    def initialize(feed)
      @feed = feed
    end

    def max_tweets
      @max_tweets ||= (Figaro.env.twitter_max_tweets || MAX_TWEETS).to_i
    end

    def client
      @client ||= Twitter::REST::Client.new do |config|
        config.consumer_key = Figaro.env.twitter_app_id
        config.consumer_secret = Figaro.env.twitter_app_secret
        config.access_token = @feed.token
        config.access_token_secret = @feed.token_secret
      end
    end

    def user_timeline?
      @feed.options.twitter_user_timeline.present?
    end

    def user_timeline_tweets(max_id = nil, n = max_tweets)
      if user_timeline?
        options = { include_rts: false, include_entities: true, count: n }
        options[:max_id] = max_id if max_id
        client.user_timeline(@feed.options.twitter_user_timeline, options).take(n)
      else
        []
      end
    end

    def home_timeline?
      @feed.options.twitter_home_timeline.to_i == 1
    end

    def home_timeline_tweets(max_id = nil, n = max_tweets)
      if home_timeline?
        options = { include_rts: false, include_entities: true, count: n }
        options[:max_id] = max_id if max_id
        client.home_timeline(options).take(n)
      else
        []
      end
    end

    def mentions_timeline?
      @feed.options.twitter_mentions_timeline.to_i == 1
    end

    def mentions_timeline_tweets(max_id = nil, n = max_tweets)
      if mentions_timeline?
        options = { include_rts: false, include_entities: true, count: n }
        options[:max_id] = max_id if max_id
        client.mentions_timeline(options).take(n)
      else
        []
      end
    end

    def search?
      @feed.options.twitter_search.present?
    end

    def search_tweets(max_id = nil, n = max_tweets)
      if search?
        hashtag = @feed.options.twitter_search.delete('#').strip
        options = { include_entities: true, count: n }
        options[:max_id] = max_id if max_id
        client.search("##{hashtag} -rt", options).take(n)
      else
        []
      end
    end

    delegate :status, to: :client
  end

  class StreamingClient
    def initialize(feed)
      @feed = feed
    end

    def client
      @client ||= Twitter::Streaming::Client.new do |config|
        config.consumer_key = Figaro.env.twitter_app_id
        config.consumer_secret = Figaro.env.twitter_app_secret
        config.access_token = @feed.token
        config.access_token_secret = @feed.token_secret
      end
    end

    def search?
      @feed.options.twitter_search.present?
    end

    def search_tweets
      if search?
        client.filter(track: @feed.options.twitter_search) do |object|
          yield object if object.is_a?(Twitter::Tweet)
        end
      end
    end
  end

  class Parser
    include Concerns::Videable
    include ActionView::Helpers::TextHelper

    def initialize(feed)
      @feed = feed
    end

    def parse(tweet)
      @tweet = tweet
      @tweet_raw_url = @tweet_media_url = nil
      @card = @feed.board.cards_collection.by_feed(@feed.id).where(external_id: @tweet.id).first || build_card_from_tweet
      merge_card_with_tweet
      @feed.board.moderate(@card)
      begin
        @feed.send_notification(:card, @card) if @card.new_record? && @card.enabled? && @card.online?
        Rails.logger.info "Cannot save card #{@tweet._id} for feed #{@feed.id}: #{@card.errors.full_messages}" unless @card.for_board(@feed.board_id).save
      rescue Moped::Errors::OperationFailure => f
      rescue => e
        Magnet.capture_exception(e, user: { email: @feed.user.to_s }, extra: { feed: @feed.name, tweet: tweet.to_s })
      end
      @card
    end

    private

    def tweet_raw_url
      @tweet_raw_url ||= begin
        if (link_in_tweet = @tweet.urls.present? && @tweet.urls.first.expanded_url.to_s) =~ /spoti.fi/
          url = URI.parse(link_in_tweet)
          redirect_with_full_uri = Net::HTTP.start(url.host, url.port) { |http| http.get(url.path) }
          link_in_tweet = redirect_with_full_uri['location']
        end
        link_in_tweet
      end
    end

    def tweet_media_url
      return @tweet_media_url if @tweet_media_url
      if @tweet.media.try(:any?)
        media = @tweet.media.first
        @tweet_media_url ||= media.media_url_https.present? ? media.media_url_https : media.media_url
      else
        @tweet_media_url ||= find_image_url(@tweet.text)
      end
    end

    def card_content_source
      if tweet_raw_url =~ /youtube|youtu.be/
        'youtube'
      elsif tweet_raw_url =~ /vimeo/
        'vimeo'
      elsif tweet_raw_url =~ /(vine.co\/v\/)/
        'vine'
      elsif tweet_raw_url =~ /spotify|spoti.fi/
        'spotify'
      end
    end

    def card_content_type
      if video_card?
        'video'
      elsif card_content_source == 'spotify'
        'audio'
      elsif @tweet.media.present?
        'image'
      else
        'text'
      end
    end

    def media_card?
      %w(vimeo youtube spotify vine).include? card_content_source
    end

    def video_card?
      %w(vimeo youtube vine).include? card_content_source
    end

    def card_media_url
      media_card? ? tweet_raw_url : tweet_media_url
    end

    def build_card_from_tweet
      Card.new do |c|
        c.external_id = @tweet.id
        c.content = @tweet.text
        c.content_source = card_content_source
        c.content_type = card_content_type
        c.from = @tweet.user.try(:screen_name)
        c.created_at = @tweet.created_at.to_datetime
        c.provider_name = 'twitter'
        c.board_id = @feed.board_id
        c.feed_id = @feed.id
        c.label = @feed.label
        c.original_content_url = "https://twitter.com/#{c.from}/status/#{c.external_id}"
        if @tweet.geo && !@tweet.geo.longitude.nil? && !@tweet.geo.latitude.nil?
          c.location = [@tweet.geo.longitude, @tweet.geo.latitude]
        end
        c.media_url = card_media_url
        c.thumbnail_image_url = resolve_thumbnail_url(c.content_source, c.media_url)
        c.tags = @tweet.hashtags.map(&:text)
      end
    end

    def merge_card_with_tweet
      @card.polled_at = Time.now
      @card.profile_image_url = @tweet.user.profile_image_url
      @card.followers_count = @tweet.user.followers_count
      @card.likes_count = @tweet.favorite_count
      @card.shares_count = @tweet.retweet_count
    end

    def find_links(doc)
      links = []
      auto_link(doc, link: :urls) do |text|
        links << text
        text
      end
      links
    end

    def image_url(link)
      return if link.blank?

      content = begin
                  Mechanize.new.get(link)
                rescue
                  nil
                end
      content.is_a?(Mechanize::Image) ? content.uri.to_s : nil
    end

    def find_image_url(content)
      if Figaro.env.search_images_in_content.to_b
        image_url find_links(content).first
      end
    end
  end

  class << self
    def options
      {
        twitter_search: [:string, '#'],
        twitter_user_timeline: [:string, '@'],
        twitter_home_timeline: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        twitter_mentions_timeline: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"]
      }
    end

    def poll(feed, oldest = false)
      if feed.pollable?
        begin
          client = Client.new(feed)
          parser = Parser.new(feed)
          max_id = oldest ? feed.board.cards_collection.by_feed(feed.id).order('external_id ASC').first.try(:external_id) : nil

          client.user_timeline_tweets(max_id).each { |t| parser.parse(t) }
          client.home_timeline_tweets(max_id).each { |t| parser.parse(t) }
          client.mentions_timeline_tweets(max_id).each { |t| parser.parse(t) }
          client.search_tweets(max_id).each { |t| parser.parse(t) }
        rescue => e
          feed.handle_polling_exception(e)
          Magnet.capture_exception(e, user: { email: feed.user.to_s }, extra: { feed: feed.name })
        ensure
          feed.update_attribute(:polling, false)
          feed.update_attribute(:polled_at, Time.now)
        end
      end
    end

    def stream(feed)
      if feed.streamable?
        while feed.live_streaming?
          begin
            client = StreamingClient.new(feed)
            parser = Parser.new(feed)

            client.search_tweets { |t| yield(client, t) ? parser.parse(t) : break }
            feed.update_attribute(:live_streaming, false)
          rescue => e
            feed.handle_polling_exception(e)
            Magnet.capture_exception(e, user: { email: feed.user.to_s }, extra: { feed: feed.name })
          ensure
            feed.update_attribute(:polling, false)
            feed.update_attribute(:polled_at, Time.now)
          end
        end
      end
    end

    def fetch(id, feed_id)
      feed = Feed.find(feed_id)
      if feed.enabled?
        client = Client.new(feed)
        parser = Parser.new(feed)
        parser.parse(client.status(id))
      end
    end

    def refresh(card)
      fetch(card.external_id, card.feed_id)
    end
  end
end
