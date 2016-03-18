class Campaign < ActiveRecord::Base
  include RankedModel
  ranks :row_order

  belongs_to :board

  scope :triggered_on, ->(t) { where('enabled = ? AND threshold >= ?', true, rand(t.to_i)) }

  validates_presence_of :name, :content
  validates :threshold, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 100 }

  def displayable?(from = Time.zone.now, to = Time.zone.now)
    (start_displaying_at.nil? || from >= start_displaying_at) && (end_displaying_at.nil? || to < end_displaying_at)
  end

  def as_card
    Card.new do |c|
      c.embed_code = content
      c.content_type = 'custom'
    end
  end
end
