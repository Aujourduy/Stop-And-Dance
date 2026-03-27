require "open3"
require "tempfile"
require "json"

class ClaudeCliIntegration
  CLAUDE_CLI_PATH = "/home/dang/.nvm/versions/node/v22.21.1/bin/claude"
  TIMEOUT_SECONDS = 120 # Increased from 60s - typical response is ~30-40s

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

      Retourne un JSON avec cette structure :
      {
        "events": [
          {
            "titre": "Titre de l'événement",
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
            "en_presentiel": true
          }
        ]
      }

      CONTENU MARKDOWN :
      #{markdown}
    PROMPT
  end

  def self.execute_cli(prompt_file_path)
    # Check auth token validity
    unless claude_authenticated?
      return { success: false, error: "Claude CLI not authenticated" }
    end

    # Execute command - pass prompt via stdin
    # Use --dangerously-skip-permissions for headless mode
    prompt_content = File.read(prompt_file_path)

    # Execute without timeout wrapper to avoid IO thread issues
    # Claude CLI has its own timeouts
    output, status = Open3.capture2e(
      CLAUDE_CLI_PATH, "--dangerously-skip-permissions",
      stdin_data: prompt_content
    )

    if status.success?
      { success: true, output: output }
    else
      { success: false, error: "CLI exited with status #{status.exitstatus}: #{output}" }
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
