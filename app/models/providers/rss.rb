require 'html/sanitizer'

class Providers::Rss
  MAX_ENTRIES = 50

  class Client
    def initialize(feed)
      @feed = feed
    end

    def max_posts
      @max_entries ||= Figaro.env.rss_max_entries || MAX_ENTRIES
    end

    def client
      Feedjira::Feed.add_common_feed_element("url", :as => :image_url)
      Feedjira::Feed.add_common_feed_entry_element("image", :as => :image)
      Feedjira::Feed.add_common_feed_entry_element("media:thumbnail", :value => :url, :as => :media_thumbnail_url)
      Feedjira::Feed.add_common_feed_entry_element("media:content", :value => :type, :as => :media_content_type)
      Feedjira::Feed.add_common_feed_entry_element("media:content", :value => :medium, :as => :media_content_medium)
      Feedjira::Feed.add_common_feed_entry_element("enclosure", :value => :url, :as => :media_thumbnail_url)
      Feedjira::Feed.add_common_feed_entry_element("enclosure", :value => :type, :as => :media_content_type)
      @client ||= Feedjira::Feed
    end

    def rss_feed?
      @feed.options.rss_feed.present?
    end

    def rss_feed(n = max_posts)
      if rss_feed?
        client.fetch_and_parse(@feed.options.rss_feed.try(:strip))
      else
        []
      end
    end

    def rss_entry(id)
    end
  end

  class Parser
    include Concerns::Videable

    def initialize(feed)
      @feed = feed
      @sanitizer = HTML::FullSanitizer.new
    end

    def parse(rss, entry)
      @entry = entry
      @entry.entry_id ||= Digest::MD5::hexdigest(@entry.url)
      @card = @feed.board.cards_collection.by_feed(@feed.id).where(:external_id => @entry.entry_id).first || build_card_from_entry(rss)
      merge_card_with_entry
      @feed.board.moderate(@card)
      begin
        @feed.send_notification(:card, @card) if @card.new_record? && @card.enabled? && @card.online?
        Rails.logger.info "Cannot save card #{@entry.entry_id} for feed #{@feed.id}: #{@card.errors.full_messages}" unless @card.for_board(@feed.board_id).save
      rescue Moped::Errors::OperationFailure => f
      rescue => e
        Magnet.capture_exception(e, user: { email: @feed.user.to_s }, extra: { feed: @feed.name, entry: entry.to_s })
      end
      @card
    end

    private

      def entry_content_type
        if @entry.media_content_type.present?
          @entry.media_content_type == 'text/html' ? 'html' :  @entry.media_content_type.split('/').first
        else
          if @entry.image.present? || @entry.media_thumbnail_url.present?
            'image'
          else
            @sanitizer.sanitize(@entry.summary) != @entry.summary ? 'html' : 'text'
          end
        end
      end

      def build_card_from_entry(rss)
        Card.new do |c|
          c.external_id = @entry.entry_id
          c.content = if @entry.title.present? && @entry.summary.present?
            "<strong>#{@entry.title}</strong><br/><br/>#{@entry.summary}"
          elsif @entry.title.present?
            @entry.title
          else
            @entry.summary
          end
          c.embed_code = @entry.content
          c.from = @entry.author || rss.title
          c.profile_image_url = rss.image_url || @feed.options.default_profile_image_url
          c.created_at = Time.at(@entry.published.to_i)
          c.provider_name = 'rss'
          c.feed_id = @feed.id
          c.label = @feed.label
          c.original_content_url = @entry.url
          c.media_url = @entry.image || @entry.media_thumbnail_url
          c.media_url = nil if c.media_url.present? && c.content.present? && c.content.include?(c.media_url)
          c.content_type = entry_content_type
          c.thumbnail_image_url = (c.is_image? ? @entry.media_thumbnail_url : nil) || @entry.image
          c.source = rss.url
        end
      end

      def merge_card_with_entry(rss = nil)
        @card.polled_at = Time.now
      end
  end

  class << self
    def options
      {
        :rss_feed => [:string, ''],
        :default_profile_image_url => [:string, '']
      }
    end

    def poll(feed, oldest = false)
      if feed.pollable?
        begin
          client = Client.new(feed)
          parser = Parser.new(feed)
          rss = client.rss_feed

          rss.entries.each { |e| parser.parse(rss, e) }
        rescue => e
          feed.handle_polling_exception(e)
          Magnet.capture_exception(e, user: { email: feed.user.to_s }, extra: { feed: feed.name })
        ensure
          feed.update_attribute(:polling, false)
          feed.update_attribute(:polled_at, Time.now)
        end
      end
    end

    def fetch(id, feed_id)
      feed = Feed.find(feed_id)
      if feed.enabled?
        client = Client.new(feed)
        parser = Parser.new(feed)
        parser.parse(client.rss_entry(id))
      end
    end

    def refresh(card)
      fetch(card.external_id, card.feed_id)
    end
  end
end
