class EventsController < ApplicationController
  include Pagy::Method

  def index
    # Detect if any filters are active
    @filtered = params[:date_debut].present? ||
                params[:atelier].present? ||
                params[:stage].present? ||
                params[:en_ligne].present? ||
                params[:en_presentiel].present? ||
                params[:gratuit].present? ||
                params[:lieu].present? ||
                params[:q].present?

    # Apply filters to base scope
    scope = apply_filters(Event.futurs.joins(:professor))

    # Calculate counts for ateliers and stages (based on filtered scope)
    @atelier_count = scope.where(type_event: :atelier).count
    @stage_count = scope.where(type_event: :stage).count

    # Pagy syntax: @pagy, @records = pagy(scope, limit: N)
    @pagy, @events = pagy(
      scope.order(:date_debut),
      limit: 30
    )

    # Fragment cache key includes filters + last updated event timestamp
    @cache_key = "events-index-#{cache_key_for_filters}-#{Event.maximum(:updated_at)&.to_i || 0}"

    respond_to do |format|
      format.html # Render full page
      format.turbo_stream # Render partial for infinite scroll
    end
  end

  def show
    @event = Event.includes(:professor).find_by(slug: params[:id])

    unless @event
      redirect_to evenements_path, alert: "Événement introuvable"
      return
    end

    # Increment professor consultation counter (atomic SQL)
    Professor.increment_counter(:consultations_count, @event.professor_id) if @event.professor_id

    # Set SEO metadata
    set_event_metadata(@event)
  end

  private

  def apply_filters(scope)
    # Filter by date_debut (events starting from this date)
    if params[:date_debut].present?
      begin
        date = Date.parse(params[:date_debut])
        scope = scope.where("date_debut >= ?", date)
      rescue ArgumentError
        # Invalid date format, ignore filter
      end
    end

    # Filter by type_event (atelier, stage)
    if params[:atelier] == "true" && params[:stage] != "true"
      scope = scope.where(type_event: :atelier)
    elsif params[:stage] == "true" && params[:atelier] != "true"
      scope = scope.where(type_event: :stage)
    end
    # If both checked or both unchecked, show all types

    # Filter by format (en_ligne, en_presentiel)
    if params[:en_ligne] == "true" && params[:en_presentiel] != "true"
      scope = scope.where(en_ligne: true)
    elsif params[:en_presentiel] == "true" && params[:en_ligne] != "true"
      scope = scope.where(en_ligne: false)
    end
    # If both checked or both unchecked, show all formats

    # Filter by gratuit
    if params[:gratuit] == "true"
      scope = scope.where(gratuit: true)
    end

    # Filter by lieu (case + accent insensitive via PG unaccent extension)
    if params[:lieu].present?
      lieu_query = "%#{params[:lieu]}%"
      scope = scope.where("unaccent(lieu) ILIKE unaccent(?)", lieu_query)
    end

    # Full-text search (AND logic: all words must match across event fields + professor name)
    # Insensible aux accents : "clement" trouve "Clément", "francois" trouve "François".
    if params[:q].present?
      words = params[:q].strip.split(/\s+/)
      words.each do |word|
        pattern = "%#{word}%"
        scope = scope.where(
          "unaccent(events.titre) ILIKE unaccent(:p) " \
          "OR unaccent(events.description) ILIKE unaccent(:p) " \
          "OR unaccent(events.lieu) ILIKE unaccent(:p) " \
          "OR unaccent(events.adresse_complete) ILIKE unaccent(:p) " \
          "OR unaccent(events.tags::text) ILIKE unaccent(:p) " \
          "OR unaccent(professors.nom) ILIKE unaccent(:p) " \
          "OR unaccent(professors.prenom) ILIKE unaccent(:p)",
          p: pattern
        )
      end
    end

    scope
  end

  def cache_key_for_filters
    # MD5 hash of filter params to ensure unique cache keys
    filter_params = params.slice(:date_debut, :atelier, :stage, :en_ligne, :en_presentiel, :gratuit, :lieu, :q)
    Digest::MD5.hexdigest(filter_params.to_json)
  end
end
