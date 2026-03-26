class ScrapingDispatchJob < ApplicationJob
  queue_as :scraping

  def perform
    ScrapedUrl.where(statut_scraping: "actif").find_each do |scraped_url|
      ScrapingJob.perform_later(scraped_url.id)
    end

    SCRAPING_LOGGER.info({
      event: "scraping_dispatch_completed",
      active_urls_count: ScrapedUrl.where(statut_scraping: "actif").count
    }.to_json)
  end
end
