class Admin::ProfessorsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_professor, only: [ :edit, :update, :mark_reviewed ]

  def index
    # Filter by status if requested
    scope = if params[:status] == "auto"
      Professor.where(status: "auto").order(created_at: :desc)
    else
      Professor.order(created_at: :desc)
    end

    if params[:photo] == "missing"
      scope = scope.where(avatar_url: [nil, ""])
    end

    if params[:q].present?
      params[:q].strip.split(/\s+/).each do |word|
        pattern = "%#{word}%"
        scope = scope.where("professors.prenom ILIKE :p OR professors.nom ILIKE :p OR professors.email ILIKE :p", p: pattern)
      end
    end

    @professors = scope.all

    # Counts for alerts
    @pending_review_count = Professor.where(status: "auto").count
    @no_photo_count = Professor.where(avatar_url: [nil, ""]).count

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def edit
    # Show form to edit professor details
  end

  def update
    # Handle photo upload
    if params[:professor][:photo].present?
      result = ProfessorPhotoService.process_upload(@professor, params[:professor][:photo])
      if result.is_a?(String)
        @professor.avatar_url = result
      else
        redirect_to edit_admin_professor_path(@professor), alert: "Erreur photo : #{result[:error]}"
        return
      end
    end

    if @professor.update(professor_params)
      redirect_to admin_professors_path, notice: "Professeur mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def mark_reviewed
    # Mark professor as reviewed (change status from "auto" to "reviewed")
    @professor.update!(status: "reviewed")
    redirect_to admin_professors_path, notice: "Professeur #{@professor.prenom} #{@professor.nom} marqué comme vérifié."
  end

  private

  def find_professor
    @professor = Professor.find(params[:id])
  end

  def professor_params
    params.require(:professor).permit(:prenom, :nom, :email, :site_web, :bio, :avatar_url)
  end
end
