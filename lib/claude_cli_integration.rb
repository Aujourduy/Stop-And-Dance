require "open3"
require "tempfile"
require "json"

class ClaudeCliIntegration
  CLAUDE_CLI_PATH = "/home/dang/.local/bin/claude"
  TIMEOUT_SECONDS = 300 # URLs volumineuses (ex. aggrégateurs multi-profs) peuvent dépasser 120s

  def self.parse_and_generate(scraped_url, html, notes_correctrices)
    # Clean HTML and convert to Markdown for better Claude parsing
    cleaned = HtmlCleaner.clean_and_convert(html)

    # Store Markdown and data_attributes for debugging/audit
    scraped_url.update(
      derniere_version_markdown: cleaned[:markdown],
      data_attributes: cleaned[:data_attributes]
    )

    SCRAPING_LOGGER.info({
      event: "html_cleaned",
      scraped_url_id: scraped_url.id,
      original_size_kb: cleaned[:original_size_kb],
      markdown_size_kb: cleaned[:markdown_size_kb],
      reduction_percent: cleaned[:reduction_percent]
    }.to_json)

    # Construct prompt with Markdown
    prompt = build_prompt(cleaned[:markdown], cleaned[:data_attributes], notes_correctrices)

    # Write prompt to temp file
    prompt_file = Tempfile.new([ "claude_prompt", ".txt" ])
    prompt_file.write(prompt)
    prompt_file.close

    # Execute Claude CLI headless
    start_time = Time.current

    result = execute_cli(prompt_file.path)

    duration_ms = ((Time.current - start_time) * 1000).to_i

    SCRAPING_LOGGER.info({
      event: "claude_cli_completed",
      scraped_url_id: scraped_url.id,
      duration_ms: duration_ms,
      success: result[:success]
    }.to_json)

    prompt_file.unlink # Clean up temp file

    if result[:success]
      # Parse JSON response
      parse_response(result[:output])
    else
      { error: result[:error] }
    end
  rescue StandardError => e
    SCRAPING_LOGGER.error({
      event: "claude_cli_failed",
      scraped_url_id: scraped_url.id,
      error: e.message
    }.to_json)
    { error: e.message }
  end

  private

  def self.build_prompt(markdown, data_attributes, notes_correctrices)
    # Load global instructions (singleton Setting)
    global_instructions = Setting.instance.claude_global_instructions

    # Build data attributes section if any structured data found
    data_section = if data_attributes.any?
      "DONNÉES STRUCTURÉES (extraites des data-attributes HTML) :\n#{JSON.pretty_generate(data_attributes)}\n\n"
    else
      ""
    end

    <<~PROMPT
      Tu es un assistant de parsing d'événements de danse.

      Le contenu de la page est fourni en Markdown (plus lisible et compact que le HTML).
      Focus sur les titres (###), listes (-), et gras (**) pour identifier les événements.

      Parse le contenu ci-dessous et extrais tous les événements (ateliers/stages de danse).

      #{global_instructions.present? ? "CONSIGNES GLOBALES :\n#{global_instructions}\n\n" : ""}

      #{notes_correctrices.present? ? "NOTES CORRECTRICES (pour cette URL spécifiquement) :\n#{notes_correctrices}\n\n" : ""}

      #{data_section}

      RÈGLES POUR LES ÉVÉNEMENTS RÉCURRENTS :

      1. Si le site LISTE des dates explicites (ex: "12 avril, 26 avril, 10 mai") :
         → Crée UN event séparé pour CHAQUE date listée. Pas de champ "recurrence".

      2. Si le site dit "tous les [jour]" ou "chaque [jour]" SANS lister les dates individuelles :
         → Crée UN SEUL event template avec le champ "recurrence" (voir schéma ci-dessous).
         → Utilise la première date trouvée comme date_debut/date_fin du template.

      3. Si le site mentionne des EXCEPTIONS ("sauf le...", "pas de cours le...", "vacances du...au...") :
         → Les mettre dans excluded_dates (dates isolées) ou excluded_ranges (périodes).

      4. "2 fois par mois" avec dates listées → cas 1 (dates explicites, PAS de recurrence).

      SYNONYMES DE TYPE D'ÉVÉNEMENT :
      - "Vague", "Vagues", "Wave", "Waves" = atelier (en danse des 5 Rythmes)
      - "Jam" = atelier
      - "Intensif", "Retraite", "Retreat", "Résidentiel" = stage

      RÈGLE HORAIRES :
      - Si l'horaire exact est mentionné sur le site, utiliser le format complet : "2026-04-12T19:30:00+02:00"
      - Si l'horaire N'EST PAS mentionné sur le site : utiliser le format DATE SEULE : "2026-04-12T00:00:00+02:00" (minuit = horaire inconnu)
      - NE PAS inventer d'horaire. Minuit signifie "horaire non renseigné".

      RÈGLE COANIMATION / MULTI-PROFS :
      - Si l'événement est animé par PLUSIEURS professeurs (duos, collectifs, format "X x Y", "avec X et Y", "chorégraphe + DJ", "coanimé par") :
        → Utiliser le champ "professeurs" (array) avec un objet par prof, dans l'ordre d'importance affiché sur le site (principal en premier).
      - Si un seul prof : utiliser quand même "professeurs" avec un seul élément.
      - Le champ "professor_nom" (ancien, singulier) est accepté pour rétrocompat mais préférer "professeurs".

      Retourne un JSON avec cette structure :
      {
        "events": [
          {
            "titre": "Titre de l'événement",
            "professeurs": [
              { "nom": "Prénom Nom du 1er prof", "photo_url": "URL portrait ou null", "role": "guide | DJ | chorégraphe | null" },
              { "nom": "Prénom Nom du 2e prof (si coanimation)", "photo_url": "URL ou null", "role": null }
            ],
            "professor_nom": "Prénom Nom du prof principal (rétrocompat, identique à professeurs[0].nom)",
            "professor_photo_url": "URL complète de la photo/avatar du professeur si visible sur la page (portrait, headshot). null si pas trouvée.",
            "description": "Description complète",
            "tags": ["Contact Improvisation", "Danse des 5 Rythmes"],
            "date_debut": "2026-03-25T19:30:00+01:00",
            "date_fin": "2026-03-25T21:30:00+01:00",
            "lieu": "Paris",
            "adresse_complete": "123 rue Example, 75001 Paris",
            "prix_normal": 25.00,
            "prix_reduit": 15.00,
            "type_event": "atelier",
            "gratuit": false,
            "en_ligne": false,
            "en_presentiel": true,
            "recurrence": null
          }
        ]
      }

      Le champ "recurrence" est null par défaut. Si récurrence détectée (cas 2), utiliser :
      {
        "recurrence": {
          "type": "weekly",
          "day_of_week": "friday",
          "time_start": "19:30",
          "time_end": "21:30",
          "start_date": "2025-09-05",
          "end_date": "2026-06-27",
          "excluded_dates": ["2026-04-18"],
          "excluded_ranges": [{"from": "2026-07-15", "to": "2026-07-30"}]
        }
      }
      - start_date : première date de la saison/période mentionnée sur le site (si mentionnée)
      - end_date : dernière date de la saison/période mentionnée sur le site (si mentionnée)
      - Si le site ne mentionne pas de période, omettre start_date et end_date

      CONTENU MARKDOWN :
      #{markdown}
    PROMPT
  end

  def self.execute_cli(prompt_file_path)
    unless claude_authenticated?
      return { success: false, error: "Claude CLI not authenticated" }
    end

    prompt_content = File.read(prompt_file_path)

    Open3.popen2e(CLAUDE_CLI_PATH, "--dangerously-skip-permissions") do |stdin, stdout_err, wait_thr|
      stdin.write(prompt_content)
      stdin.close

      deadline = Time.current + TIMEOUT_SECONDS
      output = +""

      loop do
        remaining = deadline - Time.current
        if remaining <= 0
          Process.kill("TERM", wait_thr.pid) rescue nil
          sleep 1
          Process.kill("KILL", wait_thr.pid) rescue nil
          wait_thr.join
          return { success: false, error: "CLI timeout after #{TIMEOUT_SECONDS}s" }
        end

        ready = IO.select([ stdout_err ], nil, nil, [ remaining, 1 ].min)
        if ready
          begin
            output << stdout_err.read_nonblock(65_536)
          rescue IO::WaitReadable
            next
          rescue EOFError
            break
          end
        end
      end

      status = wait_thr.value
      if status.success?
        { success: true, output: output }
      else
        { success: false, error: "CLI exited with status #{status.exitstatus}: #{output}" }
      end
    end
  rescue StandardError => e
    { success: false, error: e.message }
  end

  def self.claude_authenticated?
    # Check if Claude CLI auth file exists
    auth_file = File.expand_path("~/.claude/.credentials.json")
    File.exist?(auth_file)
  end

  def self.parse_response(output)
    # Extract JSON from output (Claude may add text before/after JSON)
    json_match = output.match(/\{.*\}/m)
    return { error: "No JSON found in output" } unless json_match

    JSON.parse(json_match[0], symbolize_names: true)
  rescue JSON::ParserError => e
    { error: "Invalid JSON: #{e.message}" }
  end
end
