class Admin::ScrapedUrlsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_scraped_url, only: [ :show, :edit, :update, :destroy, :scrape_now, :crawl_site, :fetch_with_httparty, :fetch_with_playwright, :generate_markdown, :preview, :raw_html ]

  def index
    # Build base scope
    scope = ScrapedUrl.all

    # Filtre par mots-clés sources (logique ET)
    if params[:source_filter].present?
      keywords = params[:source_filter].split(/\s+/).map(&:strip).reject(&:blank?)
      keywords.each do |keyword|
        scope = scope.where("scraped_urls.nom ILIKE ? OR scraped_urls.url ILIKE ?", "%#{keyword}%", "%#{keyword}%")
      end
    end

    # Filtre par mots-clés professeurs (logique ET)
    if params[:professor_filter].present?
      keywords = params[:professor_filter].split(/\s+/).map(&:strip).reject(&:blank?)
      keywords.each do |keyword|
        scope = scope.joins(:professors)
                     .where("professors.prenom ILIKE ? OR professors.nom ILIKE ?", "%#{keyword}%", "%#{keyword}%")
                     .distinct
      end
    end

    # Tri (default: scraped_urls.created_at DESC)
    sort_column = params[:sort].presence_in(%w[nom professors]) || "created_at"
    sort_direction = params[:direction].presence_in(%w[asc desc]) || "desc"

    case sort_column
    when "professors"
      # Sort by professor's full name (prenom + nom)
      # Get sorted IDs using a simpler SQL query, then reload objects
      sorted_ids = scope.joins("LEFT JOIN professor_scraped_urls psu ON psu.scraped_url_id = scraped_urls.id")
                        .joins("LEFT JOIN professors p ON p.id = psu.professor_id")
                        .group("scraped_urls.id")
                        .order(Arel.sql("MIN(LOWER(COALESCE(p.prenom || ' ' || p.nom, ''))) #{sort_direction}"))
                        .pluck(:id)

      # Recreate scope with sorted IDs, preserving order
      if sorted_ids.any?
        scope = ScrapedUrl.where(id: sorted_ids).order(Arel.sql("ARRAY_POSITION(ARRAY[#{sorted_ids.join(',')}]::integer[], scraped_urls.id::integer)"))
      else
        scope = ScrapedUrl.none
      end
    else
      # Specify table name to avoid ambiguity
      scope = scope.order("scraped_urls.#{sort_column} #{sort_direction}")
    end

    # Pagy syntax: @pagy, @records = pagy(scope, limit: N)
    # Must use includes to avoid N+1 after query
    @pagy, @scraped_urls = pagy(scope.includes(:professors), limit: 20)

    # Count professors pending review for dashboard alert
    @pending_professors_count = Professor.where(status: "auto").count

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

  def crawl_site
    llm_model = params[:llm_model].presence || Setting.instance.openrouter_default_model
    SiteCrawlJob.perform_later(@scraped_url.id, llm_model: llm_model)
    redirect_to admin_scraped_url_path(@scraped_url), notice: "Crawl du site lancé (modèle: #{llm_model})"
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

    # Save HTML result with timestamp
    # Always update timestamp even if HTML unchanged
    @scraped_url.assign_attributes(
      derniere_version_html: result[:html],
      derniere_version_html_at: Time.current
    )
    @scraped_url.save!(touch: false)

    redirect_to preview_admin_scraped_url_path(@scraped_url),
                notice: "HTML téléchargé avec HTTParty (#{result[:html].bytesize} bytes)"
  end

  def fetch_with_playwright
    # Test fetch with Playwright (slower, executes JavaScript)
    result = Scrapers::PlaywrightScraper.fetch(
      @scraped_url.url,
      click_selector: @scraped_url.click_selector.presence,
      detail_link_selector: (@scraped_url.enrich_detail_pages ? @scraped_url.detail_link_selector.presence : nil)
    )

    if result[:error]
      redirect_to preview_admin_scraped_url_path(@scraped_url),
                  alert: "Erreur Playwright : #{result[:error]}"
      return
    end

    # Save HTML result with timestamp
    # Always update timestamp even if HTML unchanged
    @scraped_url.assign_attributes(
      derniere_version_html: result[:html],
      derniere_version_html_at: Time.current
    )
    @scraped_url.save!(touch: false)

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

    # Call HtmlCleaner to clean and convert to Markdown
    result = HtmlCleaner.clean_and_convert(@scraped_url.derniere_version_html)

    # Save results with timestamp
    # Always update timestamp even if Markdown unchanged
    @scraped_url.assign_attributes(
      derniere_version_markdown: result[:markdown],
      data_attributes: result[:data_attributes],
      derniere_version_markdown_at: Time.current
    )
    @scraped_url.save!(touch: false)

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

        # Update timestamp after successful parsing
        @scraped_url.update!(dernier_parsing_claude_at: Time.current)
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
    params.require(:scraped_url).permit(:url, :nom, :avatar_url, :commentaire, :notes_correctrices, :statut_scraping, :use_browser, :auto_recrawl, :click_selector, :enrich_detail_pages, :detail_link_selector)
  end
end
