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

    # Expand recurring events into individual dates
    expanded_events = result[:events].flat_map { |e| RecurrenceExpander.expand(e) }

    # Create/update events
    expanded_events.each do |event_data|
      create_or_update_event(scraped_url, event_data)
    end

    SCRAPING_LOGGER.info({
      event: "events_updated",
      scraped_url_id: scraped_url_id,
      events_from_claude: result[:events].size,
      events_after_expansion: expanded_events.size
    }.to_json)
  end

  private

  def create_or_update_event(scraped_url, event_data)
    # Skip events without required dates
    return if event_data[:date_debut].blank? || event_data[:date_fin].blank?

    # Parse dates
    date_debut = Time.zone.parse(event_data[:date_debut])
    date_fin = Time.zone.parse(event_data[:date_fin])

    # Calculate type_event based on duration (ignore Claude's type_event)
    # < 5h → atelier, >= 5h → stage
    duration_hours = (date_fin - date_debut) / 3600.0
    type_event = duration_hours < 5 ? "atelier" : "stage"

    # Find or create professor by name (if provided by Claude)
    professor = find_or_create_professor(scraped_url, event_data[:professor_nom])

    # Find or create event
    # Use scraped_url + date_debut + titre as unique key
    event = Event.find_or_initialize_by(
      scraped_url: scraped_url,
      date_debut: date_debut,
      titre: event_data[:titre]
    )

    event.assign_attributes(
      description: event_data[:description],
      tags: event_data[:tags],
      date_fin: date_fin,
      lieu: event_data[:lieu],
      adresse_complete: event_data[:adresse_complete],
      prix_normal: event_data[:prix_normal],
      prix_reduit: event_data[:prix_reduit],
      type_event: type_event,
      gratuit: event_data[:gratuit],
      en_ligne: event_data[:en_ligne],
      en_presentiel: event_data[:en_presentiel],
      professor: professor
    )

    event.save!
  end

  def find_or_create_professor(scraped_url, professor_nom)
    # If no professor name provided by Claude, fallback to first professor
    if professor_nom.blank?
      return scraped_url.professors.first
    end

    # Normalize professor name for matching
    nom_normalise = Professor.normaliser_nom(professor_nom)

    # 1. Search among professors already associated with this ScrapedUrl
    professor = scraped_url.professors.find { |p| p.nom_normalise == nom_normalise }

    # 2. If not found, search globally (maybe already exists for another URL)
    professor ||= Professor.find_by(nom_normalise: nom_normalise)

    # 3. If still not found, auto-create with status "auto" (pending review)
    if professor.nil?
      # Split prenom/nom (last word = nom, rest = prenom)
      parts = professor_nom.split(' ')
      prenom = parts.length >= 2 ? parts[0..-2].join(' ') : nil
      nom = parts[-1]

      professor = Professor.create!(
        prenom: prenom,
        nom: nom,
        status: "auto",
        bio: "Professeur détecté automatiquement depuis #{scraped_url.url}"
      )

      # Associate with ScrapedUrl
      scraped_url.professors << professor

      SCRAPING_LOGGER.info({
        event: "professor_auto_created",
        professor_id: professor.id,
        professor_nom: professor_nom,
        nom_normalise: nom_normalise,
        scraped_url_id: scraped_url.id
      }.to_json)
    elsif !scraped_url.professors.include?(professor)
      # Professor exists globally but not associated with this ScrapedUrl → associate
      scraped_url.professors << professor

      SCRAPING_LOGGER.info({
        event: "professor_associated",
        professor_id: professor.id,
        scraped_url_id: scraped_url.id
      }.to_json)
    end

    # Fallback: if still nil (shouldn't happen), use first professor or raise error
    professor ||= scraped_url.professors.first
    if professor.nil?
      raise StandardError, "Aucun professor trouvé ou créé pour ScrapedUrl ##{scraped_url.id}"
    end

    professor
  end
end
