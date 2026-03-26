class Admin::EventsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_event, only: [:show, :edit, :update]

  def index
    @pagy, @events = pagy(
      Event.includes(:professor).order(date_debut: :desc),
      limit: 30
    )
  end

  def show
  end

  def edit
  end

  def update
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
      :prix_normal, :gratuit, :type_event, :en_ligne, :photo_url, :lien_inscription,
      :tags, :professor_id
    )
  end
end
