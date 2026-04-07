class ScrapedUrl < ApplicationRecord
  # Associations
  has_many :professor_scraped_urls, dependent: :destroy
  has_many :professors, through: :professor_scraped_urls
  has_many :events, dependent: :nullify
  has_many :change_logs, dependent: :destroy
  has_many :event_sources, dependent: :destroy
  has_many :site_crawls, dependent: :destroy
  belongs_to :source_site_crawl, class_name: "SiteCrawl", optional: true

  # Validations
  validates :url, presence: true, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp([ "http", "https" ]) }
end
