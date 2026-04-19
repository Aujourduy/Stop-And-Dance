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

  # Prof "propriétaire" du site : celui qui a le plus de ScrapedUrls sur ce host.
  # Utilisé comme fallback quand Claude ne trouve pas de nom explicite dans le HTML.
  def owner_professor
    host = URI(url).host rescue nil
    return professors.first if host.blank?

    Professor.joins(:scraped_urls)
      .where("scraped_urls.url LIKE ?", "%#{host}%")
      .group("professors.id")
      .order(Arel.sql("COUNT(scraped_urls.id) DESC"))
      .first || professors.first
  end
end
