class Admin::SiteCrawlsController < Admin::ApplicationController
  include Pagy::Method

  def index
    @pagy, @site_crawls = pagy(SiteCrawl.includes(:scraped_url).recent, limit: 20)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def show
    @site_crawl = SiteCrawl.find(params[:id])
    @crawled_pages = @site_crawl.crawled_pages.order(:depth, :url)
  end
end
