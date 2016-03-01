class Providers::Facebook
  MAX_POSTS = 30

  class Client
    def initialize(feed)
      @feed = feed
      @feed.refresh_token_if_expiring!
    end

    def self.search(feed, item, options = {})
      client = ::Koala::Facebook::API.new(feed.token)
      client.search(item, options)
    end

    def max_posts
      @max_posts ||= (Figaro.env.facebook_max_posts || MAX_POSTS).to_i
    end

    def client
      @client ||= ::Koala::Facebook::API.new(@feed.token)
    end

    def resolve_facebook_page_id
      if @feed.raw_options['_facebook_page_id'].blank?
        begin
          @feed.raw_options['_facebook_page_id'] = client.get_object(@feed.options.facebook_page.strip)['id']
          @feed.save(validate: false)
        rescue => e
          Rails.logger.error e
        end
      end
      @feed.raw_options['_facebook_page_id']
    end

    def facebook_search?
      @feed.options.facebook_search.present?
    end

    def facebook_tags?
      @feed.options.facebook_tags.to_i == 1
    end

    def facebook_search(max_id = nil, n = max_posts)
      if facebook_search?
        hashtag = @feed.options.facebook_search.delete('#').strip
        options = { limit: n }
        if max_id
          card = @feed.board.cards_collection.by_feed(@feed.id).order('external_id ASC').first
          options[:until] = card.created_at.to_i if card
        end
        client.search(hashtag, options)
      else
        []
      end
    end

    def facebook_photos?
      @feed.options.facebook_photos.to_i == 1 && (facebook_my_feed? || facebook_page?)
    end

    def facebook_photos(picture, id, options = {})
      if facebook_photos?
        photos = client.get_connections(id, 'photos', options)
        photos.each do |p|
          p['profile_image_url'] = picture['data']['url'] if picture && picture['data']
          p['type'] = 'photo'
          if p['source'].blank?
            if p['object_id'].present?
              o = begin
                    client.get_object(p['object_id'])
                  rescue
                    nil
                  end # Avoid unhandled exceptions when contents are not accessible
              p['source'] = o['source'] if o
            else
              p['source'] = p['picture']
            end
          end
        end
        photos
      else
        []
      end
    end

    def facebook_videos?
      @feed.options.facebook_videos.to_i == 1
    end

    def facebook_videos(picture, id, options = {})
      if facebook_videos?
        videos = client.get_connections(id, 'videos', options)
        videos.each do |v|
          v['profile_image_url'] = picture['data']['url'] if picture && picture['data']
          v['type'] = 'video'
          if v['source'].blank?
            if v['object_id'].present?
              o = begin
                    client.get_object(v['object_id'])
                  rescue
                    nil
                  end # Avoid unhandled exceptions when contents are not accessible
              v['source'] = o['source'] if o
            end
          end
        end
        videos
      else
        []
      end
    end

    def facebook_my_feed?
      @feed.options.facebook_my_feed.to_i == 1
    end

    def facebook_my_feed(max_id = nil, n = max_posts)
      if facebook_my_feed?
        options = { limit: n }
        if max_id
          card = @feed.board.cards_collection.by_feed(@feed.id).order('external_id ASC').first
          options[:until] = card.created_at.to_i if card
        end
        contents = client.get_connections('me', 'feed', options)
        contents.each do |c|
          picture = client.get_connections(c['from']['id'], 'picture?redirect=false')
          c['profile_image_url'] = picture['data']['url'] if picture && picture['data']
          if c['source'].blank?
            if c['object_id'].present?
              o = begin
                    client.get_object(c['object_id'])
                  rescue
                    nil
                  end # Avoid unhandled exceptions when contents are not accessible
              c['source'] = o['source'] if o
            else
              c['source'] = c['picture']
            end
          end
        end
        picture = client.get_connections('me', 'picture?redirect=false')
        contents += facebook_photos(picture, 'me', options) if facebook_photos?
        contents += facebook_videos(picture, 'me', options) if facebook_videos?
        contents
      else
        []
      end
    end

    def facebook_page?
      @feed.options.facebook_page.present? && @feed.options.facebook_album.blank?
    end

    def facebook_page(max_id = nil, n = max_posts)
      if facebook_page?
        page = resolve_facebook_page_id
        options = { limit: n }
        if max_id
          card = @feed.board.cards_collection.by_feed(@feed.id).order('external_id ASC').first
          options[:until] = card.created_at.to_i if card
        end
        if facebook_tags?
          pages = client.get_connections('me', 'accounts')
          facebook_page = pages.find { |p| p['id'] == page }
          if facebook_page
            page_client = ::Koala::Facebook::API.new(facebook_page['access_token'])
            contents = page_client.get_connections('me', 'tagged', options)
          end
        end
        contents ||= client.get_connections(page, 'feed', options)
        contents.each do |c|
          picture = client.get_connections(c['from']['id'], 'picture?redirect=false')
          c['profile_image_url'] = picture['data']['url'] if picture && picture['data']
          if c['source'].blank?
            if c['object_id'].present?
              o = begin
                    client.get_object(c['object_id'])
                  rescue
                    nil
                  end # Avoid unhandled exceptions when contents are not accessible
              c['source'] = o['source'] if o
            else
              c['source'] = c['picture']
            end
          end
        end
        picture = client.get_connections(page, 'picture?redirect=false')
        contents += facebook_photos(picture, page, options) if facebook_photos?
        contents += facebook_videos(picture, page, options) if facebook_videos?
        contents
      else
        []
      end
    end

    def facebook_album?
      @feed.options.facebook_page.present? && @feed.options.facebook_album.present?
    end

    def facebook_album(max_id = nil, n = max_posts)
      if facebook_album?
        page = resolve_facebook_page_id
        picture = client.get_connections(page, 'picture?redirect=false')
        options = { limit: n }
        if max_id
          card = @feed.board.cards_collection.by_feed(@feed.id).order('external_id ASC').first
          options[:until] = card.created_at.to_i if card
        end
        photos = client.get_connections(page, 'albums')
                 .sort { |a, b| b['created_time'].try(:to_time) <=> a['created_time'].try(:to_time) }.map do |album|
          if @feed.options.facebook_album == '*' || @feed.options.facebook_album == album['id']
            client.get_connections(album['id'], 'photos', options)
          end
        end.flatten.compact
        photos.each do |p|
          p['profile_image_url'] = picture['data']['url'] if picture && picture['data']
          p['type'] = 'photo'
          if p['source'].blank?
            if p['object_id'].present?
              o = begin
                    client.get_object(p['object_id'])
                  rescue
                    nil
                  end # Avoid unhandled exceptions when contents are not accessible
              p['source'] = o['source'] if o
            else
              p['source'] = p['picture']
            end
          end
        end
        photos
      else
        []
      end
    end

    def facebook_object(id)
      client.get_object(id)
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

    def card_content_type
      if @post.type == 'photo'
        'image'
      elsif @post.type == 'status' || @post.type == 'link'
        @post.picture.present? ? 'image' : 'text'
      else
        @post.type
      end
    end

    def build_card_from_post
      Card.new do |c|
        c.external_id = @post.id
        c.content = @post.message || @post.description
        c.content_type = card_content_type
        c.content_source = 'facebook'
        c.from = @post.from.try(:name)
        c.source = @post.from.try(:id)
        c.created_at = @post.created_time
        c.provider_name = 'facebook'
        c.board_id = @feed.board_id
        c.feed_id = @feed.id
        c.label = @feed.label
        c.original_content_url = @post.link || "https://www.facebook.com/#{@post.id}"
        if @post.place && @post.place.location && !@post.place.location.longitude.nil? && !@post.place.location.latitude.nil?
          c.location = [@post.place.location.longitude, @post.place.location.latitude]
        end
        c.media_url = @post.source
        c.thumbnail_image_url = @post.picture
        tags = @post.status_tags || @post.message_tags
        c.tags = tags ? tags.to_h.values.map { |a| a.map { |t| t['name'] }.flatten }.flatten : []
      end
    end

    def merge_card_with_post
      @card.polled_at = Time.now
      @card.profile_image_url = @post.from.try(:picture) || @post.profile_image_url
      @card.likes_count = @post.likes.data.try(:count) if @post.likes
      @card.shares_count = @post.shares.try(:count)
      @card.comments_count = @post.comments.try(:count)
    end
  end

  class << self
    def options
      {
        facebook_page: [:string],
        facebook_album: [:string],
        facebook_photos: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        facebook_videos: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        facebook_my_feed: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"],
        facebook_tags: [:boolean, "<i class='iconic-check'></i>", "<i class='iconic-x'></i>"]
        # :facebook_search => [:string, '#']
      }
    end

    def poll(feed, oldest = false)
      if feed.pollable?
        begin
          client = Client.new(feed)
          parser = Parser.new(feed)
          max_id = oldest ? feed.board.cards_collection.by_feed(feed.id).order('external_id ASC').first.try(:external_id) : nil

          client.facebook_my_feed(max_id).each { |p| parser.parse(p) }
          client.facebook_page(max_id).each { |p| parser.parse(p) }
          client.facebook_album(max_id).each { |p| parser.parse(p) }
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
        parser.parse(client.facebook_object(id))
      end
    end

    def refresh(card)
      fetch(card.external_id, card.feed_id)
    end
  end
end
