class SitemapsController < ApplicationController
  def index
    # Cache for 1 hour to reduce database queries
    @events = Rails.cache.fetch('sitemap/events', expires_in: 1.hour) do
      Event.futurs.order(:date_debut).to_a
    end

    @static_pages = [
      { loc: root_url, priority: 1.0 },
      { loc: about_url, priority: 0.8 },
      { loc: contact_url, priority: 0.7 },
      { loc: proposants_url, priority: 0.6 },
      { loc: evenements_url, priority: 0.9 }
    ]

    respond_to do |format|
      format.xml { render template: 'sitemaps/index', layout: false }
    end
  end
end
