class Admin::SiteCrawlsController < Admin::ApplicationController
  def index
    @site_crawls = SiteCrawl.includes(:scraped_url).recent.limit(50)
  end

  def show
    @site_crawl = SiteCrawl.find(params[:id])
    @crawled_pages = @site_crawl.crawled_pages.order(:depth, :url)
  end
end
