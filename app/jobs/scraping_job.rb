class ScrapingJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(scraped_url_id)
    scraped_url = ScrapedUrl.find(scraped_url_id)

    return unless scraped_url.statut_scraping == "actif"

    ScrapingEngine.process(scraped_url)
  end
end
