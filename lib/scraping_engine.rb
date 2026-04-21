class ScrapingEngine
  def self.process(scraped_url)
    SCRAPING_LOGGER.info({
      event: "scraping_started",
      scraped_url_id: scraped_url.id,
      url: scraped_url.url
    }.to_json)

    start_time = Time.current

    # Detect appropriate scraper based on use_browser flag
    scraper = detect_scraper(scraped_url)

    # Fetch HTML/data (PlaywrightScraper accepte click_selector + detail_link_selector
    # pour révéler contenu masqué et enrichir via pages détail).
    result = if scraper == Scrapers::PlaywrightScraper
      scraper.fetch(
        scraped_url.url,
        click_selector: scraped_url.click_selector.presence,
        detail_link_selector: (scraped_url.enrich_detail_pages ? scraped_url.detail_link_selector.presence : nil)
      )
    else
      scraper.fetch(scraped_url.url)
    end

    if result[:error]
      handle_error(scraped_url, result[:error])
      return { success: false, error: result[:error] }
    end

    # Calculate HTML hash for efficient change detection
    new_html_hash = Digest::SHA256.hexdigest(result[:html])

    # Compare with last version
    diff_result = HtmlDiffer.compare(scraped_url.derniere_version_html, result[:html])

    if diff_result[:changed]
      # Store new version with hash
      scraped_url.update!(
        derniere_version_html: result[:html],
        html_hash: new_html_hash
      )

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
        html_hash: new_html_hash,
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
  def self.detect_scraper(scraped_url)
    # Use scraped_url.use_browser to determine scraper
    # use_browser: true  → Playwright (sites JavaScript: Wix, React, Vue)
    # use_browser: false → HTTParty (sites statiques, plus rapide)
    if scraped_url.use_browser
      Scrapers::PlaywrightScraper
    else
      Scrapers::HtmlScraper
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
