class EventUpdateJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

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
      AdminNotification.notify!(
        title: "Erreur parsing Claude",
        message: "ScrapedUrl ##{scraped_url_id} (#{scraped_url.nom}): #{result[:error]}",
        category: "error",
        source: "EventUpdateJob"
      )
      raise StandardError, result[:error] # Trigger retry
    end

    # Expand recurring events into individual dates
    expanded_events = result[:events].flat_map { |e| RecurrenceExpander.expand(e) }

    # Clean slate: delete all existing events for this URL before recreating
    old_count = Event.where(scraped_url: scraped_url).delete_all

    # Create events
    expanded_events.each do |event_data|
      create_or_update_event(scraped_url, event_data)
    end

    # Deduplicate: remove events that duplicate another URL's events (same prof + date + heure)
    dedup_count = deduplicate_events(scraped_url)

    SCRAPING_LOGGER.info({
      event: "events_updated",
      scraped_url_id: scraped_url_id,
      events_deduplicated: dedup_count,
      events_deleted: old_count,
      events_from_claude: result[:events].size,
      events_after_expansion: expanded_events.size
    }.to_json)
  end

  private

  def create_or_update_event(scraped_url, event_data)
    # Skip events without required dates
    return if event_data[:date_debut].blank?

    # Parse datetime
    parsed_debut = Time.zone.parse(event_data[:date_debut])
    parsed_fin = event_data[:date_fin].present? ? Time.zone.parse(event_data[:date_fin]) : nil

    # Extract date and time separately
    date_debut_date = parsed_debut.to_date
    date_fin_date = parsed_fin&.to_date || date_debut_date

    # Heure: nil if Claude indicated "horaires à confirmer" or if time is midnight (likely invented)
    heure_debut = parsed_debut.strftime("%H:%M") == "00:00" ? nil : parsed_debut
    heure_fin = parsed_fin && parsed_fin.strftime("%H:%M") == "23:59" ? nil : parsed_fin

    # Calculate type_event
    if heure_debut.present? && heure_fin.present?
      duration_hours = (parsed_fin - parsed_debut) / 3600.0
      type_event = duration_hours < 5 ? "atelier" : "stage"
    else
      # Without hours, guess from number of days
      days = (date_fin_date - date_debut_date).to_i
      type_event = days >= 1 ? "stage" : "atelier"
    end

    # Résolution des profs : nouveau format array "professeurs" ou rétrocompat "professor_nom"
    professors_data = resolve_professors_data(event_data)

    if professors_data.empty?
      # Fallback legacy : pas de nom fourni → owner du site
      owner = scraped_url.owner_professor
      if owner.nil?
        SCRAPING_LOGGER.warn({
          event: "event_skipped_no_professor",
          scraped_url_id: scraped_url.id,
          titre: event_data[:titre]
        }.to_json)
        return
      end
      resolved_profs = [ { professor: owner, role: nil } ]
    else
      resolved_profs = professors_data.map do |pdata|
        prof = find_or_create_professor(scraped_url, pdata[:nom])
        download_prof_photo(prof, pdata[:photo_url])
        { professor: prof, role: pdata[:role] }
      end
      # Dédup : un même prof ne peut apparaître qu'une fois sur l'event
      resolved_profs = resolved_profs.uniq { |r| r[:professor].id }
    end

    # Find or create event — use date_debut_date instead of datetime for dedup
    event = Event.find_or_initialize_by(
      scraped_url: scraped_url,
      date_debut_date: date_debut_date,
      titre: event_data[:titre]
    )

    event.assign_attributes(
      description: event_data[:description],
      tags: event_data[:tags],
      date_debut_date: date_debut_date,
      date_fin_date: date_fin_date,
      heure_debut: heure_debut,
      heure_fin: heure_fin,
      lieu: event_data[:lieu],
      adresse_complete: event_data[:adresse_complete],
      prix_normal: event_data[:prix_normal],
      prix_reduit: event_data[:prix_reduit],
      type_event: type_event,
      gratuit: event_data[:gratuit],
      en_ligne: event_data[:en_ligne],
      en_presentiel: event_data[:en_presentiel],
      generated_from_recurrence: event_data[:generated_from_recurrence] || false
    )

    # Reset puis recrée les participations avant save (pour passer validation)
    if event.persisted?
      event.event_participations.delete_all
    else
      event.event_participations.clear
    end
    resolved_profs.each_with_index do |rp, idx|
      event.event_participations.build(professor: rp[:professor], role: rp[:role], position: idx)
    end
    event.save!
  end

  # Convertit event_data en array uniforme [{ nom:, photo_url:, role: }, ...]
  # Gère le nouveau format "professeurs" et rétrocompat "professor_nom"
  def resolve_professors_data(event_data)
    list = event_data[:professeurs]

    if list.is_a?(Array) && list.any?
      list.map do |p|
        next nil if p[:nom].blank?
        { nom: p[:nom].strip, photo_url: p[:photo_url], role: p[:role] }
      end.compact
    else
      nom = event_data[:professor_nom]
      return [] if nom.blank?
      [ { nom: nom.strip, photo_url: event_data[:professor_photo_url], role: nil } ]
    end
  end

  def download_prof_photo(professor, photo_url)
    return if photo_url.blank? || professor.avatar_url.present?
    begin
      result = ProfessorPhotoService.download_from_url(professor, photo_url)
      if result.is_a?(String)
        professor.update!(avatar_url: result)
        SCRAPING_LOGGER.info({ event: "professor_photo_downloaded", professor_id: professor.id, url: photo_url }.to_json)
      end
    rescue => e
      SCRAPING_LOGGER.error({ event: "professor_photo_failed", professor_id: professor.id, error: e.message }.to_json)
    end
  end

  def find_or_create_professor(scraped_url, professor_nom)
    # If no professor name provided by Claude, fallback to the owner of the site
    # (professor with the most ScrapedUrls on this host). Avoids arbitrary
    # attribution when the URL aggregates multiple collaborators.
    if professor_nom.blank?
      return scraped_url.owner_professor
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
      parts = professor_nom.split(" ")
      prenom = parts.length >= 2 ? parts[0..-2].join(" ") : nil
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

  # Remove duplicate events:
  # 1. Cross-URL: same prof + date + heure from different URLs → keep most complete
  # 2. Intra-URL: same prof + date + heure from same URL → keep explicit over recurrent
  def deduplicate_events(scraped_url)
    count = 0

    Event.where(scraped_url: scraped_url).find_each do |event|
      # Dedup par prof principal (event.professor_id, auto-synced via participations)
      primary_id = event.professor_id
      next if primary_id.blank?

      # Cross-URL dedup
      cross_dup = Event.where.not(scraped_url: scraped_url)
                       .where(professor_id: primary_id, date_debut_date: event.date_debut_date)
                       .where(heure_debut: event.heure_debut)
                       .first

      if cross_dup
        keep, remove = pick_best(cross_dup, event)
        remove.destroy
        count += 1
        log_dedup(keep, remove, "cross_url")
        next
      end

      # Intra-URL dedup (same URL, same prof + date + heure, different titre)
      intra_dup = Event.where(scraped_url: scraped_url)
                       .where(professor_id: primary_id, date_debut_date: event.date_debut_date)
                       .where(heure_debut: event.heure_debut)
                       .where.not(id: event.id)
                       .first

      if intra_dup
        keep, remove = pick_best(event, intra_dup)
        remove.destroy
        count += 1
        log_dedup(keep, remove, "intra_url")
      end
    end
    count
  end

  # Pick which event to keep: explicit > recurrent, then most complete
  def pick_best(a, b)
    # Explicit always wins over recurrent
    if a.generated_from_recurrence && !b.generated_from_recurrence
      return [ b, a ]
    elsif !a.generated_from_recurrence && b.generated_from_recurrence
      return [ a, b ]
    end

    # Both same type → keep the most complete
    completeness_score(a) >= completeness_score(b) ? [ a, b ] : [ b, a ]
  end

  def completeness_score(event)
    score = 0
    score += 1 if event.titre.present?
    score += 2 if event.description.present?
    score += 2 if event.heure_debut.present?
    score += 1 if event.lieu.present?
    score += 2 if event.adresse_complete.present?
    score += 1 if event.prix_normal.present?
    score += 1 if event.tags.present? && event.tags.any?
    score
  end

  def log_dedup(keep, remove, reason)
    SCRAPING_LOGGER.info({
      event: "event_deduplicated",
      reason: reason,
      kept_id: keep.id,
      kept_titre: keep.titre,
      removed_id: remove.id,
      removed_titre: remove.titre,
      professor: keep.professor&.nom,
      date: keep.date_debut_date.to_s,
      kept_recurrent: keep.generated_from_recurrence,
      removed_recurrent: remove.generated_from_recurrence
    }.to_json)
  end
end
