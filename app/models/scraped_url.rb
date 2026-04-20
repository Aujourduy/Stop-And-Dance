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

  # Callbacks
  after_commit :process_avatar_url, on: [ :create, :update ], if: :saved_change_to_avatar_url?

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

  private

  # Télécharge l'avatar distant, détecte sa couleur dominante si
  # rectangulaire, produit une version carrée en /avatars/ et met à
  # jour avatar_url pour pointer vers le fichier local.
  def process_avatar_url
    return if avatar_url.blank? || avatar_url.start_with?("/")

    result = ScrapedUrlAvatarService.download_and_square(self, avatar_url)
    if result.is_a?(String)
      update_column(:avatar_url, result) # éviter de re-trigger en boucle
    else
      Rails.logger.warn("ScrapedUrl ##{id} avatar processing failed: #{result[:error]}")
    end
  end
end
