class Team < ActiveRecord::Base
  has_many :users, dependent: :nullify
  has_many :categories, dependent: :destroy
  has_many :campaigns, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
