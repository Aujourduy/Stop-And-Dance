class CrawledPage < ApplicationRecord
  belongs_to :site_crawl

  validates :url, presence: true
  validates :url, uniqueness: { scope: :site_crawl_id }
  validates :depth, numericality: { greater_than_or_equal_to: 0 }

  scope :classified_yes, -> { where(llm_verdict: true) }
  scope :classified_no, -> { where(llm_verdict: false) }
end
