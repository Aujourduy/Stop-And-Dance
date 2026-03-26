class ProfessorsController < ApplicationController
  before_action :find_professor, only: [:show, :stats, :redirect_to_site]

  def show
    # Increment consultation counter (atomic SQL)
    Professor.increment_counter(:consultations_count, @professor.id)

    # Load upcoming events
    @upcoming_events = @professor.events.futurs.order(:date_debut).limit(10)

    # Set SEO metadata
    set_professor_metadata(@professor)
  end

  def stats
    # Public stats page (no authentication required)
    # Set SEO metadata
    set_stats_metadata(@professor)
  end

  def redirect_to_site
    # Increment outbound clicks counter (atomic SQL)
    Professor.increment_counter(:clics_sortants_count, @professor.id)

    # Redirect to professor's website
    redirect_to @professor.site_web, allow_other_host: true, status: :see_other
  end

  private

  def find_professor
    @professor = Professor.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to evenements_path, alert: "Professeur introuvable"
  end
end
