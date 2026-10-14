class Post < ApplicationRecord
  belongs_to :category, optional: true
  has_many :post_tags, dependent: :destroy
  has_many :tags, through: :post_tags

  has_one_attached :cover_image

  validates :title, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :body, presence: true
  validates :status, presence: true
  validate :acceptable_cover_image

  enum :status, { draft: 0, published: 1 }

  before_validation :generate_slug, on: :create
  before_save :sanitize_body

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

  def sanitize_body
    return unless body_changed?
    # Strip dangerous HTML tags while allowing safe formatting and media
    self.body = ActionController::Base.helpers.sanitize(
      body,
      tags: %w[
        p br strong em u h1 h2 h3 h4 h5 h6 ul ol li a img blockquote code pre span div hr
        video audio source iframe
      ],
      # sanitize's `attributes:` option takes a FLAT list applied to all
      # tags — a per-tag hash is silently ignored, which stripped every
      # attribute (img src/alt/class) from stored bodies. Protocol safety
      # (javascript: URLs etc.) stays enforced by rails-html-sanitizer's
      # default URI filter.
      attributes: %w[
        href src alt title class controls poster width height frameborder
        allowfullscreen allow type loading data-embed
      ]
    )
  end

  def acceptable_cover_image
    return unless cover_image.attached?

    unless cover_image.content_type.in?(%w[image/jpeg image/png image/webp])
      errors.add(:cover_image, "must be a JPEG, PNG, or WebP image")
      cover_image.purge
    end
  end
end
