class Providers::Tumblr
  MAX_POSTS = 50

  class Client
    def initialize(feed)
      @feed = feed
    end

    def max_posts
      @max_posts ||= (Figaro.env.twitter_max_posts || MAX_POSTS).to_i
    end

    def client
      @client ||= Faraday.new(url: 'http://api.tumblr.com')
    end

    def tumblr_blog?
      @feed.options.tumblr_blog.present?
    end

    def tumblr_blog_posts(offset = nil, n = max_posts)
      if tumblr_blog?
        options = {
          api_key: Figaro.env.tumblr_app_id,
          tag: @feed.options.tumblr_tag.try(:strip),
          notes_info: true,
          filter: 'text',
          limit: n
        }
        options[:offset] = offset if offset
        response = client.get("/v2/blog/#{@feed.options.tumblr_blog.try(:strip)}.tumblr.com/posts", options)
        if response.success?
          JSON.parse(response.body)['response']['posts']
        else
          []
        end
      else
        []
      end
    end

    def tumblr_tag?
      @feed.options.tumblr_tag.present?
    end

    def tumblr_tag_posts(before = nil, n = max_posts)
      if tumblr_tag?
        options = {
          api_key: Figaro.env.tumblr_app_id,
          tag: @feed.options.tumblr_tag.try(:strip),
          filter: 'text',
          limit: n
        }
        options[:before] = before.to_i if before
        response = client.get('/v2/tagged', options)
        if response.success?
          JSON.parse(response.body)['response']
        else
          []
        end
      else
        []
      end
    end

    def tumblr_post(blog, id)
      options = {
        api_key: Figaro.env.tumblr_app_id,
        notes_info: true,
        filter: 'text',
        id: id
      }
      response = client.get("/v2/blog/#{blog.strip}.tumblr.com/posts", options)
      if response.success?
        JSON.parse(response.body)['response']['posts'].try(:first)
      end
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
        Raven.capture_exception(e)
      end
      @card
    end

    private

    def post_raw_url
      if photo_card? && @post.photos.any?
        @post.photos.first['alt_sizes'].first['url']
      elsif video_card? && card_embed_code
        card_embed_code[/iframe.*?src="(.*?)"/i, 1] || card_embed_code[/video.*?src="(.*?)"/i, 1]
      end
    end

    def post_video_thumbnail
      card_embed_code[/video.*?poster=['"](.*?)['"]/i, 1] if card_embed_code
    end

    def card_content_source
      if @post.type == 'video'
        if post_raw_url =~ /youtube|youtu.be/
          'youtube'
        elsif post_raw_url =~ /vimeo/
          'vimeo'
        elsif post_raw_url =~ /(vine.co\/v\/)/
          'vine'
        elsif post_raw_url =~ /spotify|spoti.fi/
          'spotify'
        end
      end
    end

    def card_content_type
      if video_card?
        'video'
      elsif photo_card?
        'image'
      else
        'text'
      end
    end

    def media_card?
      %w(video audio photo).include? @post.type
    end

    def video_card?
      @post.type == 'video'
    end

    def photo_card?
      @post.type == 'photo'
    end

    def card_embed_code
      @post['player'].first['embed_code'] if video_card? && @post['player'].any?
    end

    def card_content
      if media_card?
        @post.caption
      else
        @post.body
      end
    end

    def card_media_url
      if video_card?
        if card_content_source == 'vine'
          "https://vine.co/v/#{vine_uid(post_raw_url)}"
        elsif card_content_source == 'youtube'
          card_embed_code
        else
          card_embed_code[/source.*?src="(.*?)"/i, 1]
        end
      else
        post_raw_url
      end
    end

    def build_card_from_post
      Card.new do |c|
        c.external_id = @post.id
        c.content = card_content
        c.content_source = card_content_source
        c.content_type = card_content_type
        c.from = @post.blog_name
        c.created_at = @post.date.to_datetime
        c.provider_name = 'tumblr'
        c.board_id = @feed.board_id
        c.feed_id = @feed.id
        c.label = @feed.label
        c.original_content_url = @post.post_url
        c.media_url = card_media_url
        c.embed_code = card_embed_code
        c.thumbnail_image_url = video_card? && c.content_source.blank? ? post_video_thumbnail : resolve_thumbnail_url(c.content_source, c.media_url)
        c.tags = @post.tags
        c.source = @post.blog_name
      end
    end

    def merge_card_with_post
      @card.polled_at = Time.now
      @card.profile_image_url = "http://api.tumblr.com/v2/blog/#{@post.blog_name}.tumblr.com/avatar"
      if @post.notes.try(:any?)
        @card.likes_count = @post.notes.count { |n| n.type == 'like' }
        @card.shares_count = @post.notes.count { |n| n.type == 'reblog' }
      end
    end
  end

  class << self
    def options
      {
        tumblr_tag: [:string, '#'],
        tumblr_blog: [:string, '', '.tumblr.com']
      }
    end

    def poll(feed, oldest = false)
      if feed.pollable?
        begin
          client = Client.new(feed)
          parser = Parser.new(feed)
          offset = oldest ? feed.board.cards_collection.by_feed(feed.id).count : nil
          before = oldest ? feed.board.cards_collection.by_feed(feed.id).order('external_id ASC').first.try(:created_at) : nil

          client.tumblr_blog_posts(offset).each { |p| parser.parse(p) }
          client.tumblr_tag_posts(before).each { |p| parser.parse(p) }
        rescue => e
          feed.handle_polling_exception(e)
          Raven.capture_exception(e)
        ensure
          feed.update_attribute(:polling, false)
          feed.update_attribute(:polled_at, Time.now)
        end
      end
    end

    def stream(_feed)
      fail NotImplementedError
    end

    def fetch(source, id, feed_id)
      feed = Feed.find(feed_id)
      if feed.enabled? && source.present?
        client = Client.new(feed)
        parser = Parser.new(feed)
        parser.parse(client.tumblr_post(source, id))
      end
    end

    def refresh(card)
      fetch(card.source, card.external_id, card.feed_id)
    end
  end
end
