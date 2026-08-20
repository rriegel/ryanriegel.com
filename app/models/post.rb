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
    return if self.slug.present?
    base_slug = title&.parameterize
    return unless base_slug.present?

    candidate = base_slug
    counter = 1
    while Post.exists?(slug: candidate)
      candidate = "#{base_slug}-#{counter}"
      counter += 1
    end
    self.slug = candidate
  end
end
