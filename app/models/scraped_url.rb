class ScrapedUrl < ApplicationRecord
  # Associations
  has_many :professor_scraped_urls, dependent: :destroy
  has_many :professors, through: :professor_scraped_urls
  has_many :events, dependent: :nullify
  has_many :change_logs, dependent: :destroy
  has_many :event_sources, dependent: :destroy

  # Validations
  validates :url, presence: true, uniqueness: true, format: { with: URI::DEFAULT_PARSER.make_regexp(['http', 'https']) }
end
