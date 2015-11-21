require 'file_size_validator'

class Category < ActiveRecord::Base
  PER_PAGE = 12

  include Swagger::Blocks

  swagger_schema :Category do
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
    property :label do
      key :type, :string
      key :description, 'label (can be used as a tag)'
    end
    property :image_url do
      key :type, :string
      key :description, 'main image URL'
    end
    property :cover_url do
      key :type, :string
      key :description, 'cover image URL'
    end
    property :ancestry do
      key :type, :string
      key :description, 'full ancestry path'
    end
    property :boards_count do
      key :type, :integer
      key :description, 'number of boards belonging to this category'
    end
  end

  swagger_schema :CategoryTreeNode do
    allOf do
      schema do
        key :'$ref', :Category
      end
      schema do
        property :children do
          key :type, :array
          items do
            key :'$ref', :CategoryTreeNode
          end
        end
      end
    end
  end

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
