# Epic 3: Automated Scraping Engine - Stories

Enable the system to automatically discover and update event information from professor websites without manual intervention.

**User Outcome:** Events are automatically scraped from professor websites every 24h, changes detected, and event data updated via Claude CLI with zero manual work.

**FRs covered:** FR13-FR17, FR39-FR44, NFR-R1 à R4, ARCH-14, ARCH-16 à ARCH-20

---

## Story 3.1: HtmlDiffer Service for Change Detection

As a system,
I want to detect when HTML content of a scraped URL has changed since last scraping,
So that I only trigger expensive Claude CLI parsing when changes are detected.

**Acceptance Criteria:**

**Given** a ScrapedUrl with stored `derniere_version_html`
**When** I fetch new HTML and compare with stored version
**Then** `lib/html_differ.rb` service exists with:

```ruby
class HtmlDiffer
  def self.compare(old_html, new_html)
    return { changed: false, diff: nil } if old_html == new_html

    # Normalize HTML (remove whitespace differences, comments)
    normalized_old = normalize_html(old_html)
    normalized_new = normalize_html(new_html)

    return { changed: false, diff: nil } if normalized_old == normalized_new

    # Generate diff
    diff_output = generate_diff(normalized_old, normalized_new)

    {
      changed: true,
      diff: diff_output,
      changements_detectes: extract_changes(diff_output)
    }
  end

  private

  def self.normalize_html(html)
    # Remove HTML comments
    html = html.gsub(/<!--.*?-->/m, '')
    # Collapse multiple spaces/newlines
    html = html.gsub(/\s+/, ' ')
    # Remove trailing/leading whitespace
    html.strip
  end

  def self.generate_diff(old_html, new_html)
    # Use Diffy gem or custom diff algorithm
    require 'diffy'
    Diffy::Diff.new(old_html, new_html, context: 3).to_s(:html)
  end

  def self.extract_changes(diff_output)
    # Parse diff output to extract structured change information
    # Returns JSON-serializable hash for changements_detectes column
    {
      lines_added: count_additions(diff_output),
      lines_removed: count_deletions(diff_output),
      timestamp: Time.current.iso8601
    }
  end
end
```

**And** `diffy` gem added to Gemfile for HTML diff generation
**And** normalization removes: HTML comments, extra whitespace, trailing/leading spaces
**And** diff output is HTML-formatted for display in admin interface
**And** `changements_detectes` is JSON-serializable hash stored in ChangeLog.changements_detectes jsonb column
**And** service returns `{ changed: false }` if normalized HTML is identical (avoids false positives from whitespace changes)
**And** service is tested with fixtures:
  - Identical HTML → `changed: false`
  - HTML with only whitespace differences → `changed: false`
  - HTML with content changes → `changed: true` with diff output

---

## Story 3.2: Generic HTML Scraper (Default Strategy)

As a scraping engine,
I want to fetch HTML from standard HTTP/HTTPS websites,
So that I can scrape professor websites that publish events as HTML pages.

**Acceptance Criteria:**

**Given** a ScrapedUrl with standard HTTP/HTTPS URL
**When** I fetch HTML content
**Then** `lib/scrapers/html_scraper.rb` exists with:

```ruby
module Scrapers
  class HtmlScraper
    USER_AGENT = "3graces.community bot - contact@3graces.community"

    def self.fetch(url)
      # Check robots.txt compliance first (NFR-S1)
      return { error: "Disallowed by robots.txt" } unless robots_allowed?(url)

      response = HTTParty.get(
        url,
        headers: { 'User-Agent' => USER_AGENT },
        timeout: 30,
        follow_redirects: true
      )

      if response.success?
        {
          html: response.body,
          status: response.code,
          content_type: response.headers['content-type']
        }
      else
        {
          error: "HTTP #{response.code}: #{response.message}",
          status: response.code
        }
      end
    rescue StandardError => e
      {
        error: e.message,
        status: nil
      }
    end

    private

    def self.robots_allowed?(url)
      # Use robots gem or custom implementation
      # Returns true if bot is allowed to scrape this URL
      require 'robots'
      robots = Robots.new(USER_AGENT)
      robots.allowed?(url)
    rescue
      # If robots.txt fetch fails, assume allowed (defensive approach)
      true
    end
  end
end
```

**And** `httparty` gem installed for HTTP requests
**And** `robots` gem installed for robots.txt compliance checking (NFR-S1)
**And** custom user-agent `"3graces.community bot - contact@3graces.community"` identifies scraping bot (NFR-S4)
**And** timeout set to 30 seconds to avoid hanging on slow sites
**And** follows HTTP redirects automatically
**And** returns hash with `:html` key on success, `:error` key on failure
**And** respects robots.txt: returns error if URL disallowed by robots.txt
**And** logs scraping activity to `SCRAPING_LOGGER`:
  - Success: `{ event: 'html_fetched', url: url, duration_ms: duration, status: 200 }`
  - Error: `{ event: 'html_fetch_failed', url: url, error: error_message }`

---

## Story 3.3: Scraper Platform Detection (Placeholder for Future Specialization)

As a scraping engine,
I want to detect platform-specific URLs for potential future specialized parsing,
So that the architecture supports adding platform-specific scrapers later.

**Acceptance Criteria:**

**Given** HtmlScraper handles all URL types for MVP
**When** ScrapingEngine detects URL pattern
**Then** URL pattern detection exists but **all platforms use HtmlScraper for now**:

**Note:** In MVP, Google Calendar, Helloasso, and Billetweb URLs are scraped with the generic HtmlScraper (Story 3.2). Platform-specific parsing is handled by Claude CLI via `notes_correctrices` per URL.

**ScrapingEngine pattern detection (for future use):**
```ruby
# In lib/scraping_engine.rb (Story 3.4)
def self.detect_scraper(url)
  # All platforms use HtmlScraper for MVP
  # Platform detection reserved for future specialized scrapers
  case url
  when /calendar\.google\.com/i
    Scrapers::HtmlScraper # Future: GoogleCalendarScraper
  when /helloasso\.com/i
    Scrapers::HtmlScraper # Future: HelloassoScraper
  when /billetweb\.fr/i
    Scrapers::HtmlScraper # Future: BilletwebScraper
  else
    Scrapers::HtmlScraper
  end
end
```

**Rationale:**
- Google Calendar, Helloasso, Billetweb HTML structures are all different
- MVP: Claude CLI is smart enough to parse any HTML structure via prompts + notes_correctrices
- Creating 3 specialized scrapers that just call HTTParty.get() is duplication with zero benefit
- Platform-specific parsing logic will be in Claude CLI prompts (guided by notes_correctrices per URL)
- Future optimization: if scraping performance becomes an issue, add specialized parsers that extract structured data BEFORE calling Claude CLI

**And** HtmlScraper (Story 3.2) handles all URL types
**And** Platform-specific parsing instructions stored in ScrapedUrl.notes_correctrices
**And** Claude CLI reads notes_correctrices to adapt parsing per platform (Story 3.5)

---

## Story 3.4: ScrapingEngine Orchestrator with URL Pattern Detection

As a scraping system,
I want an orchestrator that selects the appropriate scraper based on URL pattern,
So that each URL is scraped with the most efficient strategy.

**Acceptance Criteria:**

**Given** a ScrapedUrl to process
**When** ScrapingEngine.process(scraped_url) is called
**Then** `lib/scraping_engine.rb` exists with:

```ruby
class ScrapingEngine
  def self.process(scraped_url)
    SCRAPING_LOGGER.info({
      event: 'scraping_started',
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

      # Enqueue EventUpdateJob (will call Claude CLI)
      EventUpdateJob.perform_later(scraped_url.id)

      # Reset error counter on success
      scraped_url.update!(erreurs_consecutives: 0)

      duration_ms = ((Time.current - start_time) * 1000).to_i
      SCRAPING_LOGGER.info({
        event: 'scraping_completed',
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
        event: 'scraping_completed',
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

  private

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

  def self.handle_error(scraped_url, error_message)
    scraped_url.increment!(:erreurs_consecutives)

    SCRAPING_LOGGER.error({
      event: 'scraping_failed',
      scraped_url_id: scraped_url.id,
      url: scraped_url.url,
      error: error_message,
      erreurs_consecutives: scraped_url.erreurs_consecutives
    }.to_json)

    # Trigger alert if 3+ consecutive failures
    if scraped_url.erreurs_consecutives >= 3
      AlertEmailJob.perform_later(scraped_url.id)
    end
  end
end
```

**And** URL pattern detection uses regex case-insensitive matching
**And** default scraper is HtmlScraper if no pattern matches
**And** successful scraping resets `erreurs_consecutives` to 0
**And** error increments `erreurs_consecutives` counter
**And** 3+ consecutive errors triggers AlertEmailJob (< 15min alert via NFR-R3)
**And** all actions logged to `SCRAPING_LOGGER` with structured JSON
**And** duration tracked in milliseconds
**And** ChangeLog created only when changes detected
**And** EventUpdateJob enqueued only when changes detected (saves Claude CLI costs)

---

## Story 3.5: Claude CLI Headless Integration

As an event update system,
I want to parse HTML via Claude Code CLI headless mode,
So that I can generate structured event data from raw HTML automatically.

**Acceptance Criteria:**

**Given** HTML content and notes_correctrices
**When** I invoke Claude CLI to parse events
**Then** `lib/claude_cli_integration.rb` exists with:

```ruby
class ClaudeCliIntegration
  CLAUDE_CLI_PATH = "/usr/local/bin/claude" # Adjust path if needed
  TIMEOUT_SECONDS = 60 # NFR-I1: < 60s per URL

  def self.parse_and_generate(scraped_url, html, notes_correctrices)
    # Construct prompt
    prompt = build_prompt(html, notes_correctrices)

    # Write prompt to temp file
    prompt_file = Tempfile.new(['claude_prompt', '.txt'])
    prompt_file.write(prompt)
    prompt_file.close

    # Execute Claude CLI headless
    start_time = Time.current

    result = execute_cli(prompt_file.path)

    duration_ms = ((Time.current - start_time) * 1000).to_i

    SCRAPING_LOGGER.info({
      event: 'claude_cli_completed',
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
      event: 'claude_cli_failed',
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

    # Execute command with --dangerously-skip-permissions flag
    # NOTE: Claude CLI syntax may evolve. Validate exact syntax at implementation time.
    # Possible syntaxes:
    #   cat prompt_file | claude -p - --dangerously-skip-permissions
    #   claude -p "$(cat prompt_file)" --dangerously-skip-permissions
    # Using stdin redirect for now:
    command = "cat #{prompt_file_path} | #{CLAUDE_CLI_PATH} -p - --dangerously-skip-permissions"

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
    # NOTE: Auth file path may vary. Verify with `claude auth status` at implementation time.
    # Possible locations: ~/.claude/auth, ~/.claude/config.json, etc.
    auth_file = File.expand_path("~/.claude/auth")
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
```

**And** Claude CLI executed with `--dangerously-skip-permissions` flag for headless mode
**And** timeout enforced at 60 seconds (NFR-I1)
**And** prompt includes `notes_correctrices` if present (FR40, FR41)
**And** response parsed as JSON with event array
**And** authentication check verifies `~/.claude/auth` exists before execution
**And** timeout error returns gracefully without crashing job
**And** JSON extraction handles Claude text output before/after JSON block
**And** all Claude CLI invocations logged with duration and success status

---

## Story 3.6: ScrapingJob and EventUpdateJob

As a background job system,
I want automated jobs for scraping and event updates,
So that scraping runs on cron schedule and event data is updated automatically.

**Acceptance Criteria:**

**Given** Solid Queue configured with cron schedule
**When** cron triggers daily scraping
**Then** `app/jobs/scraping_job.rb` exists:

```ruby
class ScrapingJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(scraped_url_id)
    scraped_url = ScrapedUrl.find(scraped_url_id)

    return unless scraped_url.statut_scraping == 'actif'

    ScrapingEngine.process(scraped_url)
  end
end
```

**And** `app/jobs/event_update_job.rb` exists:

```ruby
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
        event: 'event_update_failed',
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
      event: 'events_updated',
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
```

**And** ScrapingDispatchJob exists to enqueue scraping for all active URLs:

```ruby
# app/jobs/scraping_dispatch_job.rb
class ScrapingDispatchJob < ApplicationJob
  queue_as :scraping

  def perform
    ScrapedUrl.where(statut_scraping: 'actif').find_each do |scraped_url|
      ScrapingJob.perform_later(scraped_url.id)
    end

    SCRAPING_LOGGER.info({
      event: 'scraping_dispatch_completed',
      active_urls_count: ScrapedUrl.where(statut_scraping: 'actif').count
    }.to_json)
  end
end
```

**And** Solid Queue cron configured in `config/initializers/solid_queue.rb`:
```ruby
# NOTE: Solid Queue recurring_tasks launches ONE job, not N jobs with dynamic args
# ScrapingDispatchJob enqueues individual ScrapingJobs for each active URL
config.recurring_tasks = [
  {
    name: 'Daily scraping dispatch',
    class_name: 'ScrapingDispatchJob',
    schedule: '0 3 * * *' # 3 AM daily
  }
]
```

**And** retry strategy: exponential backoff, max 3 attempts (5s, 25s, 125s delays)
**And** jobs queued to `:scraping` queue (not `:default`)
**And** EventUpdateJob creates events with `find_or_initialize_by` to avoid duplicates
**And** Event unique key: `scraped_url_id + date_debut + titre`
**And** InvalidateFragmentCacheJob enqueued after events updated (not in this story, but noted as dependency)
**And** all job executions logged to `SCRAPING_LOGGER`

---

## Story 3.7: Rake Tasks for Manual Scraping Control

As an administrator,
I want rake tasks to manually trigger scraping for testing and debugging,
So that I can test scrapers without waiting for cron schedule.

**Acceptance Criteria:**

**Given** scraping system configured
**When** I run rake tasks
**Then** `lib/tasks/scraping.rake` exists with:

```ruby
namespace :scraping do
  desc "Run scraping for all active URLs"
  task run_all: :environment do
    active_urls = ScrapedUrl.where(statut_scraping: 'actif')

    puts "Enqueueing scraping for #{active_urls.count} URLs..."

    active_urls.each do |scraped_url|
      ScrapingJob.perform_later(scraped_url.id)
      puts "  - Enqueued: #{scraped_url.url}"
    end

    puts "Done. Jobs enqueued to :scraping queue."
  end

  desc "Run scraping for specific URL by ID: rake scraping:run[123]"
  task :run, [:scraped_url_id] => :environment do |t, args|
    scraped_url = ScrapedUrl.find(args[:scraped_url_id])

    puts "Enqueueing scraping for: #{scraped_url.url}"
    ScrapingJob.perform_later(scraped_url.id)
    puts "Done. Job enqueued to :scraping queue."
  end

  desc "Dry-run test scraping for URL (no DB write): rake scraping:test[123]"
  task :test, [:scraped_url_id] => :environment do |t, args|
    scraped_url = ScrapedUrl.find(args[:scraped_url_id])

    puts "\n=== DRY-RUN TEST: #{scraped_url.url} ==="
    puts "Notes correctrices: #{scraped_url.notes_correctrices.presence || '(none)'}"
    puts "\nFetching HTML..."

    scraper = case scraped_url.url
              when /calendar\.google\.com/i
                Scrapers::GoogleCalendarScraper
              when /helloasso\.com/i
                Scrapers::HelloassoScraper
              when /billetweb\.fr/i
                Scrapers::BilletwebScraper
              else
                Scrapers::HtmlScraper
              end

    result = scraper.fetch(scraped_url.url)

    if result[:error]
      puts "ERROR: #{result[:error]}"
      exit 1
    end

    puts "HTML fetched (#{result[:html].size} bytes)"
    puts "\nParsing with Claude CLI..."

    parse_result = ClaudeCliIntegration.parse_and_generate(
      scraped_url,
      result[:html],
      scraped_url.notes_correctrices
    )

    if parse_result[:error]
      puts "PARSE ERROR: #{parse_result[:error]}"
      exit 1
    end

    puts "\nParsed #{parse_result[:events].size} event(s):"
    parse_result[:events].each_with_index do |event, i|
      puts "\n--- Event #{i + 1} ---"
      puts "Titre: #{event[:titre]}"
      puts "Date début: #{event[:date_debut]}"
      puts "Date fin: #{event[:date_fin]}"
      puts "Lieu: #{event[:lieu]}"
      puts "Prix: #{event[:prix_normal]}€#{event[:prix_reduit] ? " (réduit: #{event[:prix_reduit]}€)" : ''}"
      puts "Type: #{event[:type_event]}"
      puts "Tags: #{event[:tags].join(', ')}"
    end

    puts "\n=== DRY-RUN COMPLETED (no DB changes) ==="
  end
end
```

**And** `rake scraping:run_all` enqueues jobs for all active URLs
**And** `rake scraping:run[123]` enqueues job for specific URL by ID
**And** `rake scraping:test[123]` performs dry-run without writing to database
**And** dry-run test:
  - Fetches HTML via appropriate scraper
  - Parses with Claude CLI
  - Displays parsed events in terminal
  - Does NOT create Event records
  - Does NOT update ScrapedUrl.derniere_version_html
  - Does NOT create ChangeLog
**And** all tasks use `:environment` dependency to load Rails
**And** tasks output progress to terminal for visibility

---

## Epic 3 Summary

**Total Stories:** 7 (Story 3.3 simplified: platform detection placeholder only, no specialized scrapers in MVP)

**All requirements covered:**
- FR13: Automatic HTML scraping via Solid Queue cron (Story 3.6)
- FR14: Content change detection via HtmlDiffer (Story 3.1)
- FR15: Claude CLI automatic event generation (Story 3.5, 3.6)
- FR16: Event data written to PostgreSQL (Story 3.6)
- FR17: ChangeLog journal maintained (Story 3.4)
- FR39: Manual URL addition via admin (Epic 9, but rake tasks here: Story 3.7)
- FR40-41: Notes correctrices read by Claude CLI (Story 3.5)
- FR42-44: Logs for scraping/parsing/errors (Stories 3.2, 3.4, 3.5, 3.6)
- NFR-R1-R4: Retry 3x, alerting, autonomous operation (Story 3.4, 3.6)
- ARCH-14: Claude CLI headless with --dangerously-skip-permissions (Story 3.5)
- ARCH-16: 4 specialized scrapers (Stories 3.2, 3.3)
- ARCH-17: HtmlDiffer service (Story 3.1)
- ARCH-18: Error handling with erreurs_consecutives (Story 3.4)
- ARCH-19: Structured logging to scraping.log (all stories)
- ARCH-20: AlertEmailJob trigger after 3 failures (Story 3.4)

**Key Deliverables:**
- HtmlDiffer service for change detection
- HtmlScraper (generic, handles all platforms in MVP)
- ScrapingEngine orchestrator with URL pattern detection (placeholder for future specialization)
- Claude CLI headless integration (<60s/URL, syntax validated at implementation)
- ScrapingJob + EventUpdateJob + ScrapingDispatchJob with retry strategy
- Solid Queue cron (24h schedule via ScrapingDispatchJob)
- Rake tasks for manual control (run_all, run[id], test[id] dry-run)
- Error handling with alerting after 3 consecutive failures

**MVP Decision:** No specialized scrapers (GoogleCalendar, Helloasso, Billetweb). Claude CLI handles all platform-specific parsing via notes_correctrices.
