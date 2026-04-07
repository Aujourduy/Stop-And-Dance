class SiteCrawlJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(scraped_url_id, llm_model: nil)
    scraped_url = ScrapedUrl.find(scraped_url_id)
    SiteCrawler.new(scraped_url, llm_model: llm_model).crawl!
  rescue => e
    SCRAPING_LOGGER.error({ event: "site_crawl_job_failed", scraped_url_id: scraped_url_id, error: e.message }.to_json)
    raise
  end
end
