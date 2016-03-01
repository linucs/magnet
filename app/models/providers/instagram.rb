class Providers::Instagram
  MAX_POSTS = 50

  class Client
    def initialize(feed)
      @feed = feed
    end

    def max_posts
      @max_posts ||= (Figaro.env.instagram_max_posts || MAX_POSTS).to_i
    end

    def client
      @client ||= ::Instagram.client(
        client_id: Figaro.env.instagram_app_id,
        client_secret: Figaro.env.instagram_app_secret,
        access_token: @feed.token
      )
    end

    def instagram_recent_media_of_user?
      @feed.options.instagram_recent_media_of_user.present?
    end

    def instagram_recent_media_of_user(max_id = nil, n = max_posts)
      if instagram_recent_media_of_user?
        user = @feed.options.instagram_recent_media_of_user.delete('@').strip
        user_id = client.user_search(user).first.try(:id)
        if user_id.present?
          options = { count: n }
          options[:max_id] = max_id if max_id
          client.user_recent_media(user_id, options)
        else
          []
        end
      else
        []
      end
    end

    def instagram_user_feed?
      @feed.options.instagram_user_feed.to_i == 1
    end

    def instagram_user_feed(max_id = nil, n = max_posts)
      if instagram_user_feed?
        options = { count: n }
        options[:max_id] = max_id if max_id
        client.user_media_feed(options)
      else
        []
      end
    end

    def instagram_user_recent_media?
      @feed.options.instagram_user_recent_media.to_i == 1
    end

    def instagram_user_recent_media(max_id = nil, n = max_posts)
      if instagram_user_recent_media?
        options = { count: n }
        options[:max_id] = max_id if max_id
        client.user_recent_media(options)
      else
        []
      end
    end

    def instagram_user_liked?
      @feed.options.instagram_user_liked.to_i == 1
    end

    def instagram_user_liked(_max_id = nil, n = max_posts)
      if instagram_user_liked?
        options = { count: n }
        client.user_liked_media(options)
      else
        []
      end
    end

    def instagram_media_popular?
      @feed.options.instagram_media_popular.to_i == 1
    end

    def instagram_media_popular(_max_id = nil, _n = max_posts)
      if instagram_media_popular?
        client.media_popular
      else
        []
      end
    end

    def instagram_tag_recent_media?
      @feed.options.instagram_tag_recent_media.present?
    end

    def instagram_tag_recent_media(_max_id = nil, n = max_posts)
      if instagram_tag_recent_media?
        tag = @feed.options.instagram_tag_recent_media.delete('#').strip
        options = { count: n }
        client.tag_recent_media(tag, options)
      else
        []
      end
    end

    def instagram_media(id)
      client.media_item(id)
    end
  end

  class Parser
    include Concerns::Videable

    def initialize(feed)
      @feed = feed
    end

    def parse(post)
      @post = RecursiveOpenStruct.new(post, recurse_over_arrays: true)
      @card = @feed.board.cards_collection.by_feed(@feed.id).where(external_id: @post.id).first || build_card_from_post
      merge_card_with_post
      @feed.board.moderate(@card)
      begin
        @feed.send_notification(:card, @card) if @card.new_record? && @card.enabled? && @card.online?
        Rails.logger.info "Cannot save card #{@post.id} for feed #{@feed.id}: #{@card.errors.full_messages}" unless @card.for_board(@feed.board_id).save
      rescue Moped::Errors::OperationFailure => f
      rescue => e
        Magnet.capture_exception(e, user: { email: @feed.user.to_s }, extra: { feed: @feed.name, post: post.to_s })
      end
      @card
    end

    private

    def build_card_from_post
      Card.new do |c|
        c.external_id = @post.id
        c.content = @post.caption.try(:text)
        c.content_type = @post.type.present? ? @post.type : 'image'
        c.from = @post.user.try(:username)
        c.created_at = Time.at(@post.created_time.to_i)
        c.provider_name = 'instagram'
        c.board_id = @feed.board_id
        c.feed_id = @feed.id
        c.label = @feed.label
        c.original_content_url = @post.link
        if @post.location && !@post.location.longitude.nil? && !@post.location.latitude.nil?
          c.location = [@post.location.longitude, @post.location.latitude]
        end
        c.media_url = begin
                        @post.send(c.content_type.pluralize).standard_resolution.url
                      rescue
                        nil
                      end
        c.thumbnail_image_url = begin
                                  @post.images.thumbnail.url
                                rescue
                                  nil
                                end
        c.tags = @post.tags
      end
    end

    def merge_card_with_post
      @card.polled_at = Time.now
      @card.profile_image_url = @post.user.profile_picture
      @card.likes_count = @post.likes.count
      @card.comments_count = @post.comments.count
    end
  end

  class << self
    def options
      {
        instagram_tag_recent_media: [:string, '#'],
        instagram_recent_media_of_user: [:string, '@'],
        instagram_user_feed: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        instagram_user_recent_media: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        instagram_user_liked: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        instagram_media_popular: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"]
      }
    end

    def poll(feed, oldest = false)
      if feed.pollable?
        begin
          client = Client.new(feed)
          parser = Parser.new(feed)
          max_id = oldest ? feed.board.cards_collection.by_feed(feed.id).order('external_id ASC').first.try(:external_id) : nil

          client.instagram_recent_media_of_user(max_id).each { |p| parser.parse(p) }
          client.instagram_user_feed(max_id).each { |p| parser.parse(p) }
          client.instagram_user_recent_media(max_id).each { |p| parser.parse(p) }
          client.instagram_user_liked(max_id).each { |p| parser.parse(p) }
          client.instagram_media_popular(max_id).each { |p| parser.parse(p) }
          client.instagram_tag_recent_media(max_id).each { |p| parser.parse(p) }
        rescue => e
          feed.handle_polling_exception(e)
          Magnet.capture_exception(e, user: { email: feed.user.to_s }, extra: { feed: feed.name })
        ensure
          feed.update_attribute(:polling, false)
          feed.update_attribute(:polled_at, Time.now)
        end
      end
    end

    def stream(_feed)
      fail NotImplementedError
    end

    def fetch(id, feed_id)
      feed = Feed.find(feed_id)
      if feed.enabled?
        client = Client.new(feed)
        parser = Parser.new(feed)
        parser.parse(client.instagram_media(id))
      end
    end

    def refresh(card)
      fetch(card.external_id, card.feed_id)
    end
  end
end
