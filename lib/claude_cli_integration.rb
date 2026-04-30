require "open3"
require "tempfile"
require "json"

class ClaudeCliIntegration
  TIMEOUT_SECONDS = 300 # URLs volumineuses (ex. aggrégateurs multi-profs) peuvent dépasser 120s

  # Trouve le binaire Claude CLI selon priorité :
  # 1. ENV CLAUDE_CLI_PATH (override explicite)
  # 2. ~/.local/share/claude/versions/X.Y.Z (binaire auto-détecté, dernière version)
  # 3. ~/.local/bin/claude (symlink standard)
  # 4. /usr/local/bin/claude (install système)
  def self.cli_path
    return ENV["CLAUDE_CLI_PATH"] if ENV["CLAUDE_CLI_PATH"].present?

    # Auto-détecter la dernière version dans ~/.local/share/claude/versions/
    versions_dir = File.expand_path("~/.local/share/claude/versions")
    if Dir.exist?(versions_dir)
      latest = Dir.children(versions_dir).sort_by { |v| Gem::Version.new(v) rescue Gem::Version.new("0") }.last
      candidate = File.join(versions_dir, latest) if latest
      return candidate if candidate && File.executable?(candidate)
    end

    # Fallbacks
    [ File.expand_path("~/.local/bin/claude"), "/usr/local/bin/claude" ].find { |p| File.executable?(p) }
  end

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

      RÈGLE HORAIRES — CRITIQUE, LIRE ATTENTIVEMENT :
      - Si l'horaire exact est mentionné sur le site (ex. "19h30-21h30", "de 10h à 13h") :
        → utiliser le format complet : "2026-04-12T19:30:00+02:00"
      - Si l'horaire N'EST PAS mentionné sur le site :
        → OBLIGATOIRE utiliser : "2026-04-12T00:00:00+02:00" (date à minuit local)
        → INTERDIT d'inventer une heure, même "plausible" (type 19h, 20h, 23h, etc.)
        → date_fin doit aussi être à "23:59:00+02:00" (fin de journée inconnue)
      - Exemples interdits si horaire absent :
        ❌ "2026-04-28T19:00:00+02:00" (heure inventée)
        ❌ "2026-04-27T23:00:00+02:00" (heure + jour inventés)
      - Si tu vois "Mardi 28 avril" sans heure → date_debut = "2026-04-28T00:00:00+02:00"
        (PAS 19h, PAS 23h, PAS 20h, JUSTE 00:00)

      RÈGLE DATES — CRITIQUE, LIRE ATTENTIVEMENT :
      - L'année par défaut si non mentionnée = année courante ou prochaine
        (si date déjà passée dans l'année courante, prendre année suivante).
      - Si une date du type "Mardi 28 avril" est donnée et que tu calcules
        le jour de la semaine, VÉRIFIE que ton année est correcte :
        le 28 avril 2026 tombe un mardi ; le 28 avril 2025 tombait un lundi.
        → Si ambigu, PRIVILÉGIE toujours la date numérique (28) sur le jour
          de semaine annoncé. Ne JAMAIS décaler la date pour "matcher" le jour.
      - Exemple correct : site dit "Mardi 28 avril" sans année
        → date_debut = "2026-04-28T00:00:00+02:00" (PAS "2026-04-27...")

      RÈGLE COANIMATION / MULTI-PROFS :
      - Si l'événement est animé par PLUSIEURS professeurs (duos, collectifs, format "X x Y", "avec X et Y", "chorégraphe + DJ", "coanimé par") :
        → Utiliser le champ "professeurs" (array) avec un objet par prof, dans l'ordre d'importance affiché sur le site (principal en premier).
      - Si un seul prof : utiliser quand même "professeurs" avec un seul élément.
      - Le champ "professor_nom" (ancien, singulier) est accepté pour rétrocompat mais préférer "professeurs".

      RÈGLE NOMS DE PROFS / DJ :
      - NE JAMAIS inclure de préfixe de titre dans le nom : "DJ", "Dr.", "Prof.", "M.", "Mme".
      - Exemples :
        ❌ "DJ Mike Polarny"   ✅ "Mike Polarny"
        ❌ "DJ Ô Djinn"        ✅ "Ô Djinn"
        ❌ "Dr. Marie Dupont"  ✅ "Marie Dupont"
      - Si le site met "avec DJ X", extraire juste "X" comme nom du prof.

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

    Open3.popen2e(cli_path, "--dangerously-skip-permissions") do |stdin, stdout_err, wait_thr|
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
