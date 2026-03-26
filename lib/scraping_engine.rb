class ScrapingEngine
  def self.process(scraped_url)
    SCRAPING_LOGGER.info({
      event: "scraping_started",
      scraped_url_id: scraped_url.id,
      url: scraped_url.url
    }.to_json)

    start_time = Time.current

    # Detect appropriate scraper
    scraper = detect_scraper(scraped_url.url)

    # Fetch HTML/data
    result = scraper.fetch(scraped_url.url)

    if result[:error]
      handle_error(scraped_url, result[:error])
      return { success: false, error: result[:error] }
    end

    # Compare with last version
    diff_result = HtmlDiffer.compare(scraped_url.derniere_version_html, result[:html])

    if diff_result[:changed]
      # Store new version
      scraped_url.update!(derniere_version_html: result[:html])

      # Create ChangeLog
      ChangeLog.create!(
        scraped_url: scraped_url,
        diff_html: diff_result[:diff],
        changements_detectes: diff_result[:changements_detectes]
      )

      # Enqueue EventUpdateJob (will call Claude CLI) - Story 3.6
      if defined?(EventUpdateJob)
        EventUpdateJob.perform_later(scraped_url.id)
      else
        SCRAPING_LOGGER.warn({
          event: "event_update_job_skipped",
          scraped_url_id: scraped_url.id,
          reason: "EventUpdateJob not defined yet (Story 3.6)"
        }.to_json)
      end

      # Reset error counter on success
      scraped_url.update!(erreurs_consecutives: 0)

      duration_ms = ((Time.current - start_time) * 1000).to_i
      SCRAPING_LOGGER.info({
        event: "scraping_completed",
        scraped_url_id: scraped_url.id,
        changes_detected: true,
        duration_ms: duration_ms
      }.to_json)

      { success: true, changed: true }
    else
      # No changes detected
      scraped_url.update!(
        derniere_version_html: result[:html],
        erreurs_consecutives: 0
      )

      duration_ms = ((Time.current - start_time) * 1000).to_i
      SCRAPING_LOGGER.info({
        event: "scraping_completed",
        scraped_url_id: scraped_url.id,
        changes_detected: false,
        duration_ms: duration_ms
      }.to_json)

      { success: true, changed: false }
    end
  rescue StandardError => e
    handle_error(scraped_url, e.message)
    { success: false, error: e.message }
  end

  # Make detect_scraper public for reuse in admin controllers (Story 9.2)
  def self.detect_scraper(url)
    case url
    when /calendar\.google\.com/i
      Scrapers::HtmlScraper # All platforms use HtmlScraper in MVP (Story 3.3)
    when /helloasso\.com/i
      Scrapers::HtmlScraper
    when /billetweb\.fr/i
      Scrapers::HtmlScraper
    else
      Scrapers::HtmlScraper # Default
    end
  end

  private

  def self.handle_error(scraped_url, error_message)
    scraped_url.reload
    scraped_url.update!(erreurs_consecutives: scraped_url.erreurs_consecutives + 1)

    SCRAPING_LOGGER.error({
      event: "scraping_failed",
      scraped_url_id: scraped_url.id,
      url: scraped_url.url,
      error: error_message,
      erreurs_consecutives: scraped_url.erreurs_consecutives
    }.to_json)

    # Trigger alert if 3+ consecutive failures - Story 3.6
    if scraped_url.erreurs_consecutives >= 3
      if defined?(AlertEmailJob)
        AlertEmailJob.perform_later(scraped_url.id)
      else
        SCRAPING_LOGGER.warn({
          event: "alert_email_job_skipped",
          scraped_url_id: scraped_url.id,
          reason: "AlertEmailJob not defined yet (Story 3.6)"
        }.to_json)
      end
    end
  end
end
