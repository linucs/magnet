require 'html/sanitizer'

class Card
  include Mongoid::Document
  include Mongoid::Timestamps

  include Geocoder::Model::Mongoid
  reverse_geocoded_by :location

  field :external_id, type: String
  field :provider_name, type: String
  field :content, type: String
  field :content_type, type: String
  field :content_source, type: String
  field :enabled, type: Boolean, default: true
  field :online, type: Boolean, default: true
  field :pinned, type: Boolean, default: false
  field :from, type: String
  field :board_id, type: Integer
  field :feed_id, type: Integer
  field :user_id, type: Integer
  field :location, type: Array
  field :media_url, type: String
  field :media_signature, type: String
  field :embed_code, type: String
  field :tags, type: Array
  field :source, type: String
  field :original_content_url, type: String
  field :profile_image_url, type: String
  field :thumbnail_image_url, type: String
  field :label, type: String
  field :rating, type: Integer
  field :followers_count, type: Integer
  field :likes_count, type: Integer
  field :shares_count, type: Integer
  field :comments_count, type: Integer
  field :notes, type: String
  field :polled_at, type: DateTime

  index({ external_id: 1 }, unique: true, drop_dups: true, background: true)
  index({ provider_name: 1 }, background: true)
  index({ feed_id: 1 }, background: true)
  index({ media_url: 1 }, background: true)
  index({ media_signature: 1 }, background: true)
  index({ enabled: 1, from: 1 }, background: true)
  index({ enabled: 1, feed_id: -1 }, background: true)
  index({ enabled: 1, online: -1 }, background: true)
  index({ enabled: 1, likes_count: -1 }, background: true)
  index({ enabled: 1, shares_count: -1 }, background: true)
  index({ enabled: 1, pinned: -1, created_at: -1 }, background: true)
  index({ enabled: 1, online: 1, pinned: -1, created_at: -1 }, background: true)

  if Figaro.env.enable_elasticsearch_indexing.to_b
    # Elasticserch index update
    update_index(->(card) { Card.index_for_board(card.board_id).index_name if card.board_id }) { self }
  end

  scope :online, -> { where(online: true) }
  scope :only_images, -> { where(content_type: 'image') }
  scope :by_feed, -> (f) { where(feed_id: f) }
  scope :by_provider, -> (p) { where(provider_name: p) }
  scope :default_order, -> { order_by([[:pinned, :desc], [:created_at, :desc]]) }
  scope :most_liked, -> (n = 10) { order_by([[:likes_count, :desc]]).limit(n) }
  scope :most_shared, -> (n = 10) { order_by([[:shares_count, :desc]]).limit(n) }
  scope :pinned, -> { where(pinned: true) }
  scope :not_pinned, -> { where(pinned: false) }

  mount_uploader :custom_profile_image, ProfileImageUploader
  mount_uploader :custom_thumbnail_image, ImageUploader
  mount_uploader :custom_media, AssetUploader

  # validates_presence_of :feed_id
  validates :content_type, inclusion: { in: %w(video audio image text html) }

  PER_PAGE = 48
  paginates_per PER_PAGE

  def for_board(id)
    with(collection: "board-#{id}")
  end

  def is_video?
    content_type == 'video'
  end

  def is_audio?
    content_type == 'audio'
  end

  def is_image?
    content_type == 'image'
  end

  def is_text?
    content_type == 'text'
  end

  def is_html?
    content_type == 'html'
  end

  def provider_title
    ENV["#{provider_name}_title"] || provider_name.try(:titleize)
  end

  def profile_image_url
    custom_profile_image.present? ? custom_profile_image : self[:profile_image_url]
  end

  def profile_url
    case provider_name
    when 'twitter' then "https://twitter.com/#{from}"
    when 'tumblr' then "https://#{source || from}.tumblr.com"
    when 'instagram' then "https://instagram.com/#{from}"
    when 'facebook' then "https://facebook.com/#{source || from}"
    else
      source
    end
  end

  def media_url
    custom_media.present? ? custom_media.url : self[:media_url]
  end

  def thumbnail_image_url
    custom_thumbnail_image.present? ? custom_thumbnail_image.url : self[:thumbnail_image_url]
  end

  def refresh
    AuthenticationProvider.instance(provider_name).refresh(self)
  end

  def self.for_board(id)
    with(collection: "board-#{id}")
  end

  def self.index_for_board(id)
    @index ||= Object.const_set("Board#{id}Index", Class.new(Chewy::Index) do
      define_type Card.for_board(id), delete_if: -> { !enabled? } do
        field :content
      end
    end)
  end

  def self.create_indexes_for_board(id)
    return unless index_specifications
    index_specifications.each do |spec|
      key = spec.key
      options = spec.options
      if database = options[:database]
        with(read: :primary, database: database, collection: "board-#{id}")
          .collection.indexes.create(key, options.except(:database))
      else
        with(read: :primary, collection: "board-#{id}").collection.indexes.create(key, options)
      end
    end && true
  end

  def self.remove_indexes_for_board(id)
    indexed_database_names.each do |database|
      collection = with(read: :primary, database: database, collection: "board-#{id}").collection
      collection.indexes.each do |spec|
        collection.indexes.drop(spec['key']) unless spec['name'] == '_id_'
      end
    end && true
  end

  def self.rebuild_indexes_for_all_boards
    Board.all.find_each do |b|
      remove_indexes_for_board(b.id) && create_indexes_for_board(b.id)
    end
  end

  def self.cleanup_dead_boards
    Board.all.find_each do |b|
      begin
        b.cards_collection.collection.capped?
      rescue
        # FIXME: linucs 20150414: I didn't find any other way to check collection existence!
        b.cards_collection.collection.drop
      end
    end
  end

  def self.cleanup_dead_feeds
    Board.all.find_each do |b|
      Chewy.strategy(:atomic) do
        b.cards_collection.where(:feed_id.nin => b.feeds.map(&:id)).destroy_all
      end
    end
  end
end
