class ProposantsController < ApplicationController
  include Pagy::Method

  def index
    today = Date.current

    # IDs des profs ayant >=1 event futur (priorité d'affichage en tête)
    with_futurs_ids = Professor.joins(:events)
                               .where("events.date_debut_date >= ?", today)
                               .distinct.pluck(:id)

    scope = Professor.all
    ids_sql = with_futurs_ids.any? ? with_futurs_ids.join(",") : "NULL"
    scope = scope.order(
      Arel.sql("CASE WHEN professors.id IN (#{ids_sql}) THEN 0 ELSE 1 END"),
      :nom,
      :prenom
    )

    if params[:q].present?
      words = params[:q].strip.split(/\s+/)
      words.each do |word|
        pattern = "%#{word}%"
        scope = scope.where(
          "professors.nom ILIKE :p OR professors.prenom ILIKE :p OR professors.bio ILIKE :p",
          p: pattern
        )
      end
    end

    @pagy, @proposants = pagy(scope, limit: 30)

    respond_to do |format|
      format.html
      format.turbo_stream # infinite scroll (page > 1)
    end
  end

  def show
    @proposant = Professor.find(params[:id])
  end
end
