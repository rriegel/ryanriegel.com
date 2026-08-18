class Post < ApplicationRecord
  belongs_to :category, optional: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  validates :title, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :body, presence: true
  validates :status, presence: true

  enum :status, { draft: 0, published: 1 }

  before_validation :generate_slug, on: :create

  scope :published, -> { where(status: :published) }
  scope :drafts, -> { where(status: :draft) }
  scope :recent, -> { order(published_at: :desc) }

  private

  def generate_slug
    self.slug ||= title&.parameterize
  end
end
