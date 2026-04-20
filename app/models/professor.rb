class Professor < ApplicationRecord
  include Normalizable

  # Associations
  has_many :professor_scraped_urls, dependent: :destroy
  has_many :scraped_urls, through: :professor_scraped_urls
  has_many :event_participations, dependent: :destroy
  has_many :events, through: :event_participations

  # Validations
  validates :nom, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :site_web, format: { with: URI::DEFAULT_PARSER.make_regexp([ "http", "https" ]) }, allow_blank: true

  # Nom affichable : "Prénom Nom" si prenom présent, sinon nom seul
  def display_nom
    prenom.present? ? "#{prenom} #{nom}" : nom
  end

  # Tags uniques extraits des events futurs (ex. "Danse des 5 Rythmes", "Contact Improvisation")
  def activites
    events.futurs.pluck(:tags).flatten.compact.uniq.reject(&:blank?).sort
  end

  # Villes uniques des events futurs
  def villes
    events.futurs.where.not(lieu: [ nil, "" ]).pluck(:lieu).uniq.sort
  end

  # URL "principale" : site_web renseigné en priorité, sinon URL la plus courte parmi scraped_urls
  # (= la racine du site, ex. "https://example.com/" plutôt que "/agenda")
  def url_principale
    return site_web if site_web.present?
    scraped_urls.pluck(:url).min_by { |u| (URI(u).path || "/").length rescue 99 }
  end

  # Autres URLs (toutes sauf principale)
  def urls_secondaires
    return scraped_urls.pluck(:url) if site_web.present?
    urls = scraped_urls.pluck(:url)
    urls - [ url_principale ]
  end
end
