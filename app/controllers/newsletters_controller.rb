class NewslettersController < ApplicationController
  def create
    @newsletter = Newsletter.new(newsletter_params)

    if @newsletter.save
      redirect_to evenements_path, notice: "Merci ! Vous êtes inscrit(e) à notre newsletter."
    else
      # Handle error (email already exists or invalid)
      if @newsletter.errors.details[:email].any? { |e| e[:error] == :taken }
        redirect_to evenements_path, notice: "Cette adresse email est déjà inscrite à notre newsletter."
      else
        redirect_to evenements_path, alert: "Erreur : #{@newsletter.errors.full_messages.join(', ')}"
      end
    end
  end

  private

  def newsletter_params
    params.require(:newsletter).permit(:email)
  end
end
