class Event < ApplicationRecord
  # Enums
  enum :type_event, { atelier: 0, stage: 1 }

  # Associations
  belongs_to :professor
  belongs_to :scraped_url, optional: true
  has_many :event_sources, dependent: :destroy
  has_many :additional_scraped_urls, through: :event_sources, source: :scraped_url

  # Validations
  validates :titre, presence: true
  validates :date_fin, comparison: { greater_than: :date_debut }
  validates :professor, presence: true

  # Callbacks
  before_save :calculate_duree_minutes
  before_save :normalize_titre
  before_validation :generate_slug

  # Scopes
  scope :futurs, -> { where("date_debut >= ?", Time.current) }

  # Helper methods
  def type_event_humanized
    I18n.t("activerecord.attributes.event.type_events.#{type_event}", default: type_event.to_s.humanize)
  end

  private

  def normalize_titre
    return if titre.blank?
    acronymes = Setting.instance.acronymes_preserves.to_s.split(",").map(&:strip).map(&:upcase).to_set
    self.titre = titre.gsub(/\b([A-ZÀ-Ü]{2,})\b/) do |word|
      acronymes.include?(word.upcase) ? word.upcase : word.capitalize
    end
  end

  def calculate_duree_minutes
    return unless date_debut.present? && date_fin.present?
    self.duree_minutes = ((date_fin - date_debut) / 60).to_i
  end

  def generate_slug
    return if titre.blank? || date_debut.blank?
    base_slug = "#{titre.parameterize}-#{lieu.to_s.parameterize}-#{date_debut.strftime('%Y-%m-%d')}"
    self.slug = base_slug
  end
end
