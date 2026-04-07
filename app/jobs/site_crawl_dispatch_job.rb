class SiteCrawlDispatchJob < ApplicationJob
  queue_as :scraping

  def perform
    ScrapedUrl.where(auto_recrawl: true).find_each do |scraped_url|
      last_crawl = scraped_url.site_crawls.completed.recent.first
      next if last_crawl.nil?

      scraper = scraped_url.use_browser ? Scrapers::PlaywrightScraper : Scrapers::HtmlScraper
      result = scraper.fetch(scraped_url.url)
      next if result[:error]

      current_hash = Digest::SHA256.hexdigest(result[:html])
      root_page = last_crawl.root_page
      next if root_page && root_page.content_hash == current_hash

      SCRAPING_LOGGER.info({ event: "site_crawl_auto_relaunch", scraped_url_id: scraped_url.id }.to_json)
      SiteCrawlJob.perform_later(scraped_url.id)
    end
  end
end
