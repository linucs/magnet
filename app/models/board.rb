require 'file_size_validator'

class Board < ActiveRecord::Base
  PER_PAGE = 24
  DEFAULT_DECK_TEMPLATE_URL = '/tpl/deck/template.html'
  DEFAULT_DECK_HEADER_URL = '/tpl/deck/header.html'
  DEFAULT_TIMELINE_TEMPLATE_URL = '/tpl/timeline/template.html'
  DEFAULT_TIMELINE_HEADER_URL = '/tpl/timeline/header.html'
  DEFAULT_WALL_TEMPLATE_URL = '/tpl/wall/template.html'
  DEFAULT_WALL_WIDTH = '100%'
  DEFAULT_WALL_HEIGHT = '100%'
  DEFAULT_WALL_PAGE_SIZE = 30
  DEFAULT_WALL_AUTO_SLIDE = 10_000
  DECK_STANDARD_THEMES = {
    'Googlish' => 'deck/themes/todc-bootstrap.css',
    'Cerulean' => 'deck/themes/cerulean.css',
    'Cosmo' => 'deck/themes/cosmo.css',
    'Cyborg' => 'deck/themes/cyborg.css',
    'Darkly' => 'deck/themes/darkly.css',
    'Flatly' => 'deck/themes/flatly.css',
    'Darkly' => 'deck/themes/darkly.css',
    'Journal' => 'deck/themes/journal.css',
    'Lumen' => 'deck/themes/lumen.css',
    'Paper' => 'deck/themes/paper.css',
    'Readable' => 'deck/themes/readable.css',
    'Sandstone' => 'deck/themes/sandstone.css',
    'Simplex' => 'deck/themes/simplex.css',
    'Slate' => 'deck/themes/slate.css',
    'Spacelab' => 'deck/themes/spacelab.css',
    'Superhero' => 'deck/themes/superhero.css',
    'United' => 'deck/themes/united.css',
    'Yeti' => 'deck/themes/yeti.css'
  }
  TIMELINE_STANDARD_THEMES = {
    'Googlish' => 'deck/themes/todc-bootstrap.css',
    'Cerulean' => 'deck/themes/cerulean.css',
    'Cosmo' => 'deck/themes/cosmo.css',
    'Cyborg' => 'deck/themes/cyborg.css',
    'Darkly' => 'deck/themes/darkly.css',
    'Flatly' => 'deck/themes/flatly.css',
    'Darkly' => 'deck/themes/darkly.css',
    'Journal' => 'deck/themes/journal.css',
    'Lumen' => 'deck/themes/lumen.css',
    'Paper' => 'deck/themes/paper.css',
    'Readable' => 'deck/themes/readable.css',
    'Sandstone' => 'deck/themes/sandstone.css',
    'Simplex' => 'deck/themes/simplex.css',
    'Slate' => 'deck/themes/slate.css',
    'Spacelab' => 'deck/themes/spacelab.css',
    'Superhero' => 'deck/themes/superhero.css',
    'United' => 'deck/themes/united.css',
    'Yeti' => 'deck/themes/yeti.css'
  }
  WALL_STANDARD_THEMES = {
    'Googlish' => 'deck/themes/todc-bootstrap.css',
    'Cerulean' => 'deck/themes/cerulean.css',
    'Cosmo' => 'deck/themes/cosmo.css',
    'Cyborg' => 'deck/themes/cyborg.css',
    'Darkly' => 'deck/themes/darkly.css',
    'Flatly' => 'deck/themes/flatly.css',
    'Darkly' => 'deck/themes/darkly.css',
    'Journal' => 'deck/themes/journal.css',
    'Lumen' => 'deck/themes/lumen.css',
    'Paper' => 'deck/themes/paper.css',
    'Readable' => 'deck/themes/readable.css',
    'Sandstone' => 'deck/themes/sandstone.css',
    'Simplex' => 'deck/themes/simplex.css',
    'Slate' => 'deck/themes/slate.css',
    'Spacelab' => 'deck/themes/spacelab.css',
    'Superhero' => 'deck/themes/superhero.css',
    'United' => 'deck/themes/united.css',
    'Yeti' => 'deck/themes/yeti.css'
  }
  TIMELINE_BACKGROUND_STYLES = [:scrolling_from_top, :full_screen, :parallax]
  WALL_BACKGROUND_STYLES = [:full_screen, :parallax]

  CUSTOM_FONT_SIZES = %w(8px 9px 10px 11px 12px 14px 16px 18px 20px 22px 24px 26px 28px 30px 32px 34px 36px 38px 40px)

  include Swagger::Blocks

  swagger_schema :Board do
    key :required, [:id, :name, :slug]
    key :description, 'A representation of a board categorization, by a particolar subject or topic'
    property :id do
      key :type, :integer
      key :description, 'internal ID'
    end
    property :name do
      key :type, :string
      key :description, 'editorial name'
    end
    property :slug do
      key :type, :string
      key :description, 'URL slug'
    end
    property :description do
      key :type, :string
      key :description, 'extended description'
    end
    property :full_street_address do
      key :type, :string
      key :description, 'event street adddress (to be used when the board contents are referred to a specific place)'
    end
    property :latitude do
      key :type, :float
      key :description, 'event location latitude (to be used when the board contents are referred to a specific place)'
    end
    property :longitude do
      key :type, :float
      key :description, 'event location longitude (to be used when the board contents are referred to a specific place)'
    end
    property :label do
      key :type, :string
      key :description, 'label (can be used as a tag)'
    end
    property :icon_url do
      key :type, :string
      key :description, 'icon image URL'
    end
    property :image_url do
      key :type, :string
      key :description, 'main image URL'
    end
    property :cover_url do
      key :type, :string
      key :description, 'cover image URL'
    end
    property :category_id do
      key :type, :integer
      key :description, 'internal ID of the category this board belongs to'
    end
  end

  include RankedModel
  ranks :row_order

  extend FriendlyId
  friendly_id :name, use: :slugged

  mount_uploader :icon, ImageUploader
  mount_uploader :image, ImageUploader
  mount_uploader :cover, ImageUploader

  serialize :options

  belongs_to :category
  has_many :feeds, dependent: :delete_all do
    def with_alerts
      @alerts ||= where('last_exception IS NOT NULL')
    end
  end
  has_and_belongs_to_many :users do
    def pick_one
      @buffer ||= cycle
      @buffer.next if @buffer.size > 0
    end
  end
  has_many :campaigns, dependent: :nullify

  after_create :index_cards_collection
  before_destroy :cleanup_cards_collection

  has_shortened_urls

  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates_uniqueness_of :host, if: 'host.present?'
  validates :image, file_size: { maximum: 0.5.megabytes.to_i }

  scope :enabled, -> { where(enabled: true) }

  paginates_per PER_PAGE

  def options
    OpenStruct.new(self[:options])
  end

  def raw_options
    self[:options]
  end

  def self.poll_enabled
    Board.where(enabled: true).find_each { |b| b.poll if b.check_polling_count! }
  end

  def polled_at
    @polled_at ||= feeds.maximum('polled_at')
  end

  def live_streaming?
    feeds.exists?(live_streaming: true)
  end

  def banner_url
    @banner ||= if image.present?
                  image.url
                else
                  cards.only_images.online.first.try(:thumbnail_image_url)
    end
  end

  def polling?
    feeds.where(polling: true).count > 0
  end

  def check_polling_count!
    if polling_interval.to_i > 0
      update_attribute(:polling_count, (polling_count.to_i + 1) % polling_interval)
      polling_count == 0
    else
      false
    end
  end

  def moderate(card)
    now = Time.now
    card.enabled = false if card.content_type == 'text' && !include_text_only_cards?
    if card.enabled?
      card.enabled = !banned_user?(card.from)
      card.notes = "Discarded at #{now}: user #{card.from} is banned." unless card.enabled?
    end
    if card.enabled? && card.media_url.present? && card.new_record?
      card.enabled = !cards_collection.where(media_url: card.media_url).exists?
      card.notes = "Discarded at #{now}: an identical attached media was found." unless card.enabled?
      if card.enabled? && card.is_image? && discard_identical_images?
        card.media_signature = begin
                                 MiniMagick::Image.open(card.media_url).signature
                               rescue
                                 nil
                               end
        card.enabled = !cards_collection.where(media_signature: card.media_signature).exists? if card.media_signature.present?
        card.notes = "Discarded at #{now}: an identical attached media URL was found." unless card.enabled?
      end
    end
    if card.enabled? && card.new_record?
      if trusted_user?(card.from)
        card.online = true
        card.notes = "Approved at #{now}: user #{card.from} is trusted."
      else
        card.online = !moderated?
        if card.online? && max_tags_per_card.to_i > 0 && card.tags.try(:any?)
          card.online = card.tags.size <= max_tags_per_card.to_i
          card.notes = "Blacklisted at #{now}: too many hashtags were present." unless card.online?
        end
        if card.online? && card.content.present? && discard_obscene_contents?
          self.blacklist = :default
          card.online = !profane?(card.content)
          card.notes = "Blacklisted at #{now}: classified as profane or obscene." unless card.online?
        end
        if card.online? && card.content.present? && banned_words.present?
          self.blacklist = banned_words.split(',')
          card.online = !profane?(card.content)
          card.notes = "Blacklisted at #{now}: contains one or more stopwords." unless card.online?
        end
      end
      card.user_id = users.pick_one.try(:id) unless card.online?
    end
  end

  def pollable?(from = Time.zone.now, to = Time.zone.now)
    (start_polling_at.nil? || from >= start_polling_at) && (end_polling_at.nil? || to < end_polling_at)
  end

  def poll(options = {})
    feeds.each { |f| f.poll(options) } if pollable? || options[:force]
  end

  def cards(c = nil)
    (c || cards_collection).where(enabled: true)
  end

  def all_cards
    cards_collection.where(enabled: true)
  end

  def cards_collection
    Card.with(collection: "board-#{id}")
  end

  def search_cards(q = nil, order = nil)
    q ||= {}
    q.delete(:from_eq) if q[:from_eq].blank?
    selector = RansackMongo::Query.parse(q)
    collection = cards.where(selector)
    collection = if order == 'most_liked'
                   collection.most_liked
                 elsif order == 'most_shared'
                   collection.most_shared
                 else
                   collection.default_order
                 end
  end

  def trust_user(user)
    if user.to_s.present?
      self.trusted_users = "#{trusted_users},#{user.to_s.strip}"
      update_attribute(:trusted_users, trusted_users.gsub(/^,/, ''))
    end
  end

  def ban_user(user)
    if user.to_s.present?
      self.banned_users = "#{banned_users},#{user.to_s.strip}"
      update_attribute(:banned_users, banned_users.gsub(/^,/, ''))
    end
  end

  def unban_user(user)
    if user.to_s.present? && banned_users.present?
      banned_users.gsub!(user.to_s.strip, '')
      banned_users.gsub!(/,,+/, ',')
      banned_users.gsub!(/,$/, '')
      banned_users.gsub!(/^,/, '')
    end
  end

  def trusted_user?(user)
    if user.to_s.present? && trusted_users.present?
      !(/,#{user.to_s.strip},/.match(",#{trusted_users},").nil?)
    end
  end

  def banned_user?(user)
    if user.to_s.present? && banned_users.present?
      !(/,#{user.to_s.strip},/.match(",#{banned_users},").nil?)
    end
  end

  def index_cards_collection
    Card.create_indexes_for_board(id)
  end

  def cleanup_cards_collection
    BoardCleanupWorker.perform_async(id)
  end

  def self.create_from_csv(file, user, create_missing_categories, poll_immediately, options = {})
    board = category = provider = nil
    CSV.foreach(file.path, headers: true, col_sep: "\t") do |row|
      if row['hashtag_or_user_or_blog_or_page'].present?
        target = row['hashtag_or_user_or_blog_or_page'].strip
        label = row['label'].try(:strip)
        category_name = row['category_name'].try(:strip)
        board_name = row['board_name'].try(:strip)
        board_description = row['board_description'].try(:strip)
        provider_name = row['provider_name'].try(:strip)
        unless Figaro.env.disable_uploads.to_b
          icon_url = row['icon_url'].try(:strip)
          image_url = row['image_url'].try(:strip)
          cover_url = row['cover_url'].try(:strip)
        end
        provider = user.authentication_providers.find_by(name: provider_name) if provider_name.present?
        if category_name.present?
          category = create_missing_categories ? Category.ensure_tree(category_name) : Category.find_by(name: category_name)
        end
        Board.transaction do
          board = user.boards.create({
            name: board_name,
            description: board_description,
            category: category,
            remote_icon_url: icon_url,
            remote_image_url: image_url,
            remote_cover_url: cover_url }.merge(options)) if board_name.present?
          if board.errors.empty?
            providers = provider ? [provider] : user.authentication_providers
            providers.each do |p|
              feed_options = if target.starts_with?('#')
                               h = target.delete('#')
                               case p.name
                               when 'twitter' then { twitter_search: h }
                               when 'tumblr' then { tumblr_tag: h }
                               when 'instagram' then { instagram_tag_recent_media: h }
                               end
                             else
                               u = target.delete('@')
                               case p.name
                               when 'twitter' then { twitter_user_timeline: u }
                               when 'tumblr' then { tumblr_blog: u }
                               when 'instagram' then { instagram_recent_media_of_user: u }
                               when 'facebook' then { facebook_page: u }
                               end
              end
              unless feed_options.nil?
                feed = Feed.new(board: board, authentication_provider: p, user: user, label: label, options: feed_options)
                if feed.save
                  feed.poll(high_priority: true) if poll_immediately
                else
                  yield "Cannot parse #{target} (row ##{$INPUT_LINE_NUMBER}). #{feed.errors.full_messages.join(': ')}" if block_given?
                  fail ActiveRecord::Rollback
                end
              end
            end
          else
            yield "#{target} (row ##{$INPUT_LINE_NUMBER}): this row cannot be imported. #{board.errors.full_messages.join(': ')}" if block_given?
          end
        end unless user.boards.exists?(name: board_name)
      end
    end
  end

  def blacklist
    @blacklist ||= set_list_content(Obscenity.config.blacklist)
  end

  def blacklist=(value)
    @blacklist = value == :default ? set_list_content(Obscenity::Config.new.blacklist) : value
  end

  def whitelist
    @whitelist ||= set_list_content(Obscenity.config.whitelist)
  end

  def whitelist=(value)
    @whitelist = value == :default ? set_list_content(Obscenity::Config.new.whitelist) : value
  end

  def profane?(text)
    return(false) unless text.to_s.size >= 3
    blacklist.each do |foul|
      return(true) if text =~ /#{foul}/i && !whitelist.include?(foul)
    end
    false
  end

  def sanitize(text)
    return(text) unless text.to_s.size >= 3
    blacklist.each do |foul|
      text.gsub!(/\b#{foul}\b/i, replace(foul)) unless whitelist.include?(foul)
    end
    @scoped_replacement = nil
    text
  end

  def replacement(chars)
    @scoped_replacement = chars
    self
  end

  def offensive(text)
    words = []
    return(words) unless text.to_s.size >= 3
    blacklist.each do |foul|
      words << foul if text =~ /\b#{foul}\b/i && !whitelist.include?(foul)
    end
    words.uniq
  end

  def replace(word)
    content = @scoped_replacement || Obscenity.config.replacement
    case content
    when :vowels then word.gsub(/[aeiou]/i, '*')
    when :stars  then '*' * word.size
    when :nonconsonants then word.gsub(/[^bcdfghjklmnpqrstvwxyz]/i, '*')
    when :default, :garbled then '$@!#%'
    else content
    end
  end

  def has_feeds_from?(p)
    !feeds.find_by(authentication_provider_id: p).nil?
  end

  def topics_summary(options = {})
    match = { enabled: { '$eq' => true } }
    if options
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      '$group' => { _id: '$feed_id', count: { '$sum' => 1 } }
    ).map(&:values).map do |i|
      [(begin
                                         Feed.find(i[0]).name
                                       rescue
                                         'n/a'
                                       end), i[1]]
    end
  end

  def top_contributors(options = {})
    limit = 10
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$group' => { _id: '$from', count: { '$sum' => 1 } } },
      { '$sort' => { count: -1 } },
      '$limit' => limit
    ).map(&:values)
  end

  def top_influencers(options = {})
    limit = 10
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    mean = cards_collection.collection.aggregate(
      { '$match' => match },
      '$group' => {
        _id: nil,
        count: { '$sum' => 1 },
        likes: { '$avg' => '$likes_count' },
        shares: { '$avg' => '$shares_count' },
        comments: { '$avg' => '$comments_count' }
      }
    ).first

    unless mean.nil?
      cards_collection.collection.aggregate(
        { '$match' => match },
        { '$group' => {
          _id: '$from',
          count: { '$sum' => 1 },
          likes: { '$sum' => { '$multiply' => ['$likes_count', '$likes_count'] } },
          shares: { '$sum' => { '$multiply' => ['$shares_count', '$shares_count'] } },
          comments: { '$sum' => { '$multiply' => ['$comments_count', '$comments_count'] } }
        }
        },
        { '$project' => {
          _id: 1,
          count: { '$subtract' => [
            { '$divide' => [{ '$add' => ['$likes', '$shares', '$comments'] }, mean['count']] },
            mean['likes'].to_f**2 + mean['shares'].to_f**2 + mean['comments'].to_f**2
          ]
            }
        }
        },
        { '$sort' => { count: -1 } },
        '$limit' => limit
      ).map(&:values).map { |v| [v[0], v[1] < 0 ? 0 : Math.sqrt(v[1])] }
    end
  end

  def most_engaging_people(options = {})
    limit = 10
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    # weights = cards_collection.collection.aggregate(
    #   {'$match' => match},
    #   {'$group' => {
    #     _id: nil,
    #     likes: {'$sum' => '$likes_count'},
    #     shares: {'$sum' => '$shares_count'},
    #     comments: {'$sum' => '$comments_count'},
    #     total: {'$sum' => {
    #       '$add' => [
    #         {'$ifNull' => ['$likes_count', 0]},
    #         {'$ifNull' => ['$shares_count', 0]},
    #         {'$ifNull' => ['$comments_count', 0]}
    #         ]
    #       }}
    #     }
    #   },
    #   {'$project' => {
    #     _id: 0,
    #     likes: {'$divide' => ['$likes', '$total']},
    #     shares: {'$divide' => ['$shares', '$total']},
    #     comments: {'$divide' => ['$comments', '$total']}
    #     }
    #   }
    # ).first

    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$group' => {
        _id: '$from',
        count: { '$sum' => 1 },
        likes: { '$sum' => '$likes_count' },
        shares: { '$sum' => '$shares_count' },
        comments: { '$sum' => '$comments_count' },
        # likes: {'$sum' => {'$divide' => ['$likes_count', weights['likes']]}},
        # shares: {'$sum' => {'$divide' => ['$shares_count', weights['shares']]}},
        # likes: {'$sum' => {'$divide' => ['$comments_count', weights['comments']]}}
      }
      },
      { '$project' => {
        _id: 1,
        count: { '$divide' => [{ '$add' => [
          { '$ifNull' => ['$likes', 0] },
          { '$ifNull' => ['$shares', 0] },
          { '$ifNull' => ['$comments', 0] }
        ] }, '$count'] }
      }
      },
      { '$sort' => { count: -1 } },
      '$limit' => limit
    ).map(&:values)
  end

  def most_liked_people(options = {})
    limit = 10
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$group' => { _id: '$from', count: { '$sum' => '$likes_count' } } },
      { '$sort' => { count: -1 } },
      '$limit' => limit
    ).map(&:values)
  end

  def most_shared_people(options = {})
    limit = 10
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$group' => { _id: '$from', count: { '$sum' => '$shares_count' } } },
      { '$sort' => { count: -1 } },
      '$limit' => limit
    ).map(&:values)
  end

  def most_commented_people(options = {})
    limit = 10
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$group' => { _id: '$from', count: { '$sum' => '$comments_count' } } },
      { '$sort' => { count: -1 } },
      '$limit' => limit
    ).map(&:values)
  end

  def buzz(options = {})
    match = { enabled: { '$eq' => true } }
    group = { year: { '$year' => '$created_at' }, month: { '$month' => '$created_at' }, day: { '$dayOfMonth' => '$created_at' } }
    if options
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
      match[:feed_id] = { '$eq' => options[:feed_id].to_i } if options[:feed_id].present?
      group[:hour] =  { '$hour' => '$created_at' } if options[:by] == 'hour' || options[:by] == 'minute'
      group[:minute] = { '$minute' => '$created_at' } if options[:by] == 'minute'
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$group' => { _id: group, date: { '$first' => group }, count: { '$sum' => 1 } } },
      { '$sort' => { _id: 1 } },
      '$project' => {
        _id: 0,
        date: '$date',
        count: '$count'
      }
    ).map(&:values)
  end

  def hashtags(options = {})
    limit = 20
    match = { enabled: { '$eq' => true } }
    if options
      limit = options[:limit].to_i if options[:limit].present?
      match[:provider_name] = { '$eq' => options[:provider_name] } if options[:provider_name].present?
      match[:created_at] = { '$gte' => options[:since] } if options[:since].is_a?(Time)
      match[:created_at] = { '$lt' => options[:until] } if options[:until].is_a?(Time)
    end
    cards_collection.collection.aggregate(
      { '$match' => match },
      { '$unwind' => '$tags' },
      { '$group' => { _id: { '$toLower' => '$tags' }, count: { '$sum' => 1 } } },
      { '$sort' => { count: -1 } },
      '$limit' => limit
    ).map(&:values)
  end

  def send_notification(msg, obj = self)
    WebsocketRails["board-#{id}"].trigger(msg, obj)
  end

  private

  def set_list_content(list)
    case list
    when Array then list
    when String, Pathname then YAML.load_file(list.to_s)
    else []
    end
  end
end
