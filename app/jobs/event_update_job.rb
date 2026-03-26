class EventUpdateJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(scraped_url_id)
    scraped_url = ScrapedUrl.find(scraped_url_id)
    html = scraped_url.derniere_version_html
    notes_correctrices = scraped_url.notes_correctrices

    # Parse via Claude CLI
    result = ClaudeCliIntegration.parse_and_generate(scraped_url, html, notes_correctrices)

    if result[:error]
      SCRAPING_LOGGER.error({
        event: "event_update_failed",
        scraped_url_id: scraped_url_id,
        error: result[:error]
      }.to_json)
      raise StandardError, result[:error] # Trigger retry
    end

    # Create/update events
    result[:events].each do |event_data|
      create_or_update_event(scraped_url, event_data)
    end

    SCRAPING_LOGGER.info({
      event: "events_updated",
      scraped_url_id: scraped_url_id,
      events_count: result[:events].size
    }.to_json)
  end

  private

  def create_or_update_event(scraped_url, event_data)
    # Find or create event
    # Use scraped_url + date_debut + titre as unique key
    event = Event.find_or_initialize_by(
      scraped_url: scraped_url,
      date_debut: Time.zone.parse(event_data[:date_debut]),
      titre: event_data[:titre]
    )

    event.assign_attributes(
      description: event_data[:description],
      tags: event_data[:tags],
      date_fin: Time.zone.parse(event_data[:date_fin]),
      lieu: event_data[:lieu],
      adresse_complete: event_data[:adresse_complete],
      prix_normal: event_data[:prix_normal],
      prix_reduit: event_data[:prix_reduit],
      type_event: event_data[:type_event],
      gratuit: event_data[:gratuit],
      en_ligne: event_data[:en_ligne],
      en_presentiel: event_data[:en_presentiel],
      professor: scraped_url.professors.first # Assume single professor per URL for MVP
    )

    event.save!
  end
end
