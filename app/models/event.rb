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
  validates :date_debut_date, presence: true
  validates :date_fin_date, comparison: { greater_than_or_equal_to: :date_debut_date }
  validates :professor, presence: true

  # Callbacks
  before_save :calculate_duree_minutes
  before_save :normalize_titre
  before_save :sync_legacy_datetime
  before_validation :generate_slug

  # Scopes — use date_debut_date for date-only queries
  scope :futurs, -> { where("date_debut_date >= ?", Date.current) }

  # Helper methods
  def type_event_humanized
    I18n.t("activerecord.attributes.event.type_events.#{type_event}", default: type_event.to_s.humanize)
  end

  # Backward compat: setting date_debut (datetime) auto-fills date_debut_date + heure_debut
  def date_debut=(val)
    super(val)
    return if val.blank?
    parsed = val.is_a?(String) ? Time.zone.parse(val) : val
    self.date_debut_date = parsed.to_date
    self.heure_debut = parsed if parsed.strftime("%H:%M") != "00:00"
  end

  def date_fin=(val)
    super(val)
    return if val.blank?
    parsed = val.is_a?(String) ? Time.zone.parse(val) : val
    self.date_fin_date = parsed.to_date
    self.heure_fin = parsed if parsed.strftime("%H:%M") != "23:59"
  end

  def horaire_connu?
    heure_debut.present?
  end

  def display_heure_debut
    heure_debut&.strftime("%Hh%M")
  end

  def display_heure_fin
    heure_fin&.strftime("%Hh%M")
  end

  def display_duree
    return nil unless duree_minutes.present? && duree_minutes > 0
    if duree_minutes < 60
      "#{duree_minutes}min"
    else
      h = duree_minutes / 60
      m = duree_minutes % 60
      m > 0 ? "#{h}h#{format('%02d', m)}min" : "#{h}h"
    end
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
    return unless heure_debut.present? && heure_fin.present?
    self.duree_minutes = ((heure_fin - heure_debut) / 60).to_i
  end

  def sync_legacy_datetime
    # Keep old date_debut/date_fin in sync for backward compatibility
    if date_debut_date.present?
      if heure_debut.present?
        self.date_debut = Time.zone.parse("#{date_debut_date} #{heure_debut.strftime('%H:%M')}")
      else
        self.date_debut = Time.zone.parse("#{date_debut_date} 00:00")
      end
    end
    if date_fin_date.present?
      if heure_fin.present?
        self.date_fin = Time.zone.parse("#{date_fin_date} #{heure_fin.strftime('%H:%M')}")
      else
        self.date_fin = Time.zone.parse("#{date_fin_date} 23:59")
      end
    end
  end

  def generate_slug
    return if titre.blank? || date_debut_date.blank?
    base_slug = "#{titre.parameterize}-#{lieu.to_s.parameterize}-#{date_debut_date.strftime('%Y-%m-%d')}"
    self.slug = base_slug
  end
end
