class Admin::ScrapedUrlsController < Admin::ApplicationController
  include Pagy::Method
  before_action :find_scraped_url, only: [ :show, :edit, :update, :destroy, :scrape_now, :preview ]

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

  def preview
    # Dry-run: fetch + parse without DB write
    scraper = ScrapingEngine.detect_scraper(@scraped_url.url)
    result = scraper.fetch(@scraped_url.url)

    if result[:error]
      @error = result[:error]
    else
      @html = result[:html]
      @parse_result = ClaudeCliIntegration.parse_and_generate(
        @scraped_url,
        result[:html],
        @scraped_url.notes_correctrices
      )
    end

    render :preview
  end

  private

  def find_scraped_url
    @scraped_url = ScrapedUrl.find(params[:id])
  end

  def scraped_url_params
    params.require(:scraped_url).permit(:url, :nom, :commentaire, :notes_correctrices, :statut_scraping)
  end
end
