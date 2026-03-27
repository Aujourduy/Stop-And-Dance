class Admin::EventsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_event, only: [ :show, :edit, :update ]

  def index
    # Detect if filters or sort are active
    @filtered = params[:professor_id].present? || params[:titre].present?
    @sorted = params[:sort].present?

    # Apply filters
    scope = Event.includes(:professor)
    scope = scope.where(professor_id: params[:professor_id]) if params[:professor_id].present?
    scope = scope.where("titre ILIKE ?", "%#{params[:titre]}%") if params[:titre].present?

    # Apply sorting
    scope = apply_sorting(scope)

    # If filtered or sorted, disable pagination and show all results
    if @filtered || @sorted
      @events = scope.all
      @pagy = nil
    else
      @pagy, @events = pagy(scope, limit: 30)
    end

    # Get all professors for filter dropdown
    @professors = Professor.order(:nom)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
  end

  def edit
  end

  def update
    # Convertir tags (string) en array avant save
    if params[:event][:tags].present? && params[:event][:tags].is_a?(String)
      params[:event][:tags] = params[:event][:tags].split(",").map(&:strip).reject(&:blank?)
    end

    if @event.update(event_params)
      redirect_to admin_event_path(@event), notice: "Événement mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def apply_sorting(scope)
    case params[:sort]
    when "titre_asc"
      scope.order(titre: :asc)
    when "titre_desc"
      scope.order(titre: :desc)
    when "date_asc"
      scope.order(date_debut: :asc)
    when "date_desc"
      scope.order(date_debut: :desc)
    when "professor_asc"
      scope.joins(:professor).order("professors.nom ASC")
    when "professor_desc"
      scope.joins(:professor).order("professors.nom DESC")
    else
      scope.order(date_debut: :desc) # Default sort
    end
  end

  def find_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :titre, :description, :date_debut, :date_fin, :lieu, :adresse_complete,
      :prix_normal, :prix_reduit, :gratuit, :type_event,
      :en_ligne, :en_presentiel,
      :photo_url, :lien_inscription,
      :professor_id,
      tags: []
    )
  end
end
