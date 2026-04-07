class SiteCrawl < ApplicationRecord
  belongs_to :scraped_url
  has_many :crawled_pages, dependent: :destroy
  has_many :auto_created_scraped_urls, class_name: "ScrapedUrl", foreign_key: "source_site_crawl_id", dependent: :nullify

  STATUTS = %w[pending running completed failed].freeze
  validates :statut, inclusion: { in: STATUTS }

  scope :recent, -> { order(created_at: :desc) }
  scope :completed, -> { where(statut: "completed") }

  def root_page
    crawled_pages.where(depth: 0).first
  end
end
