class Admin::EventsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_event, only: [ :show, :edit, :update ]

  def index
    @pagy, @events = pagy(
      Event.includes(:professor).order(date_debut: :desc),
      limit: 30
    )

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
