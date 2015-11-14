require 'file_size_validator'

class Category < ActiveRecord::Base
  PER_PAGE = 12

  include RankedModel
  ranks :row_order

  extend FriendlyId
  friendly_id :name, use: :slugged

  has_ancestry

  mount_uploader :image, ImageUploader
  mount_uploader :cover, ImageUploader

  has_many :boards, dependent: :nullify

  validates_presence_of :name, :slug
  validates_uniqueness_of :slug
  validates :image, file_size: { maximum: 0.5.megabytes.to_i }

  scope :enabled, -> { where(enabled: true) }

  def self.ensure_tree(path, separator = '/')
    path = path.to_s.split(separator) unless path.is_a? Array
    ancestor_ids = path.size > 1 ? ensure_tree(path[0..-2]).path_ids : nil
    Category.where(name: path[-1], ancestry: ancestor_ids.try(:join, '/')).first_or_create if path.size > 0
  end

  def to_s
    name
  end
end
