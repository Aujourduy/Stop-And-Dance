class Admin::ScrapedUrlsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_scraped_url, only: [ :show, :edit, :update, :destroy, :scrape_now, :fetch_with_httparty, :fetch_with_playwright, :generate_markdown, :preview, :raw_html ]

  def index
    # Pagy syntax: @pagy, @records = pagy(scope, limit: N)
    @pagy, @scraped_urls = pagy(
      ScrapedUrl.includes(:professors).order(created_at: :desc),
      limit: 20
    )

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @recent_change_logs = @scraped_url.change_logs.order(created_at: :desc).limit(10)
  end

  def new
    @scraped_url = ScrapedUrl.new
  end

  def create
    @scraped_url = ScrapedUrl.new(scraped_url_params)

    if @scraped_url.save
      redirect_to admin_scraped_url_path(@scraped_url), notice: "URL ajoutée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @scraped_url.update(scraped_url_params)
      redirect_to admin_scraped_url_path(@scraped_url), notice: "URL mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scraped_url.destroy
    redirect_to admin_scraped_urls_path, notice: "URL supprimée."
  end

  def scrape_now
    # Trigger immediate scraping (enqueue job)
    ScrapingJob.perform_later(@scraped_url.id)

    redirect_to admin_scraped_url_path(@scraped_url),
                notice: "Scraping lancé. Consultez les logs pour voir le résultat."
  end

  def fetch_with_httparty
    # Test fetch with HTTParty (fast, no JS execution)
    result = Scrapers::HtmlScraper.fetch(@scraped_url.url)

    if result[:error]
      redirect_to preview_admin_scraped_url_path(@scraped_url),
                  alert: "Erreur HTTParty : #{result[:error]}"
      return
    end

    # Save HTML result
    @scraped_url.update!(derniere_version_html: result[:html])

    redirect_to preview_admin_scraped_url_path(@scraped_url),
                notice: "HTML téléchargé avec HTTParty (#{result[:html].bytesize} bytes)"
  end

  def fetch_with_playwright
    # Test fetch with Playwright (slower, executes JavaScript)
    result = Scrapers::PlaywrightScraper.fetch(@scraped_url.url)

    if result[:error]
      redirect_to preview_admin_scraped_url_path(@scraped_url),
                  alert: "Erreur Playwright : #{result[:error]}"
      return
    end

    # Save HTML result
    @scraped_url.update!(derniere_version_html: result[:html])

    redirect_to preview_admin_scraped_url_path(@scraped_url),
                notice: "HTML téléchargé avec Playwright (#{result[:html].bytesize} bytes)"
  end

  def generate_markdown
    # Convert HTML → Markdown + data-attributes (HtmlCleaner)
    if @scraped_url.derniere_version_html.blank?
      redirect_to preview_admin_scraped_url_path(@scraped_url),
                  alert: "Aucun HTML en cache. Lancez un scraping d'abord."
      return
    end

    # Call HtmlCleaner to extract data-attributes and convert to Markdown
    result = HtmlCleaner.extract_and_convert(@scraped_url.derniere_version_html)

    # Save results
    @scraped_url.update!(
      derniere_version_markdown: result[:markdown],
      data_attributes: result[:data_attributes]
    )

    redirect_to preview_admin_scraped_url_path(@scraped_url),
                notice: "Markdown généré avec succès ! (#{result[:markdown].bytesize} bytes)"
  end

  def preview
    # Use cached data (HTML + Markdown + previous parsing) instead of re-fetching
    if @scraped_url.derniere_version_html.blank?
      @error = "Aucun HTML en cache. Lancez un scraping d'abord."
    else
      @html = @scraped_url.derniere_version_html

      # Use previously parsed events if available, otherwise parse now
      if params[:force_parse] == "true"
        # Force re-parsing with Claude (takes ~30-60s)
        @parse_result = ClaudeCliIntegration.parse_and_generate(
          @scraped_url,
          @html,
          @scraped_url.notes_correctrices
        )
      else
        # Show events already in database (instant)
        events = Event.where(scraped_url_id: @scraped_url.id).limit(20).map do |e|
          {
            titre: e.titre,
            description: e.description,
            tags: e.tags,
            date_debut: e.date_debut.iso8601,
            date_fin: e.date_fin.iso8601,
            lieu: e.lieu,
            adresse_complete: e.adresse_complete,
            prix_normal: e.prix_normal,
            prix_reduit: e.prix_reduit,
            type_event: e.type_event,
            gratuit: e.gratuit,
            en_ligne: e.en_ligne,
            en_presentiel: e.en_presentiel
          }
        end
        @parse_result = { events: events }
      end
    end

    render :preview
  end

  def raw_html
    # Serve raw HTML for iframe rendering
    if @scraped_url.derniere_version_html.present?
      render html: @scraped_url.derniere_version_html.html_safe, layout: false
    else
      render html: "<h1>Aucun HTML disponible</h1>".html_safe, layout: false
    end
  end

  private

  def find_scraped_url
    @scraped_url = ScrapedUrl.find(params[:id])
  end

  def scraped_url_params
    params.require(:scraped_url).permit(:url, :nom, :commentaire, :notes_correctrices, :statut_scraping, :use_browser)
  end
end
