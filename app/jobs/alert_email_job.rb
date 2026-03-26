class AlertEmailJob < ApplicationJob
  queue_as :notifications

  def perform(scraped_url_id)
    scraped_url = ScrapedUrl.find(scraped_url_id)

    # Log alert for MVP (email sending will be implemented in Epic 8)
    SCRAPING_LOGGER.warn({
      event: "alert_triggered",
      scraped_url_id: scraped_url_id,
      url: scraped_url.url,
      erreurs_consecutives: scraped_url.erreurs_consecutives,
      message: "3+ consecutive scraping errors - manual intervention needed"
    }.to_json)

    # TODO Epic 8: Send actual email alert
    # AdminMailer.scraping_error_alert(scraped_url).deliver_later
  end
end
