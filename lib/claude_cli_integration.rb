require "open3"
require "tempfile"
require "json"

class ClaudeCliIntegration
  CLAUDE_CLI_PATH = "/home/dang/.nvm/versions/node/v22.21.1/bin/claude"
  TIMEOUT_SECONDS = 60 # NFR-I1: < 60s per URL

  def self.parse_and_generate(scraped_url, html, notes_correctrices)
    # Construct prompt
    prompt = build_prompt(html, notes_correctrices)

    # Write prompt to temp file
    prompt_file = Tempfile.new(["claude_prompt", ".txt"])
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

  def self.build_prompt(html, notes_correctrices)
    <<~PROMPT
      Tu es un assistant de parsing d'événements de danse.

      Parse le HTML ci-dessous et extrais tous les événements (ateliers/stages de danse).

      #{notes_correctrices.present? ? "NOTES CORRECTRICES :\n#{notes_correctrices}\n\n" : ""}

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

      HTML :
      #{html}
    PROMPT
  end

  def self.execute_cli(prompt_file_path)
    # Check auth token validity
    unless claude_authenticated?
      return { success: false, error: "Claude CLI not authenticated" }
    end

    # Execute command - read prompt from file and pass via stdin
    # Use --dangerously-skip-permissions for headless mode
    command = "cat #{prompt_file_path} | #{CLAUDE_CLI_PATH} --dangerously-skip-permissions"

    output, status = Open3.capture2e(command, timeout: TIMEOUT_SECONDS)

    if status.success?
      { success: true, output: output }
    else
      { success: false, error: "CLI exited with status #{status.exitstatus}: #{output}" }
    end
  rescue Timeout::Error
    { success: false, error: "Claude CLI timeout (> #{TIMEOUT_SECONDS}s)" }
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
