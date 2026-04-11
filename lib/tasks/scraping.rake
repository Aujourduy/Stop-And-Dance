namespace :scraping do
  desc "Run scraping for all active URLs"
  task run_all: :environment do
    active_urls = ScrapedUrl.where(statut_scraping: "actif")

    puts "Enqueueing scraping for #{active_urls.count} URLs..."

    active_urls.each do |scraped_url|
      ScrapingJob.perform_later(scraped_url.id)
      puts "  - Enqueued: #{scraped_url.url}"
    end

    puts "Done. Jobs enqueued to :scraping queue."
  end

  desc "Run scraping for specific URL by ID: rake scraping:run[123]"
  task :run, [ :scraped_url_id ] => :environment do |t, args|
    scraped_url = ScrapedUrl.find(args[:scraped_url_id])

    puts "Enqueueing scraping for: #{scraped_url.url}"
    ScrapingJob.perform_later(scraped_url.id)
    puts "Done. Job enqueued to :scraping queue."
  end

  desc "Dry-run scraping pipeline for all active URLs (no DB write). Reports ✅/❌ per URL."
  task dry_run: :environment do
    results = ScrapingDryRun.run_all
    ScrapingDryRun.print_report(results)
  end

  desc "Dry-run test scraping for URL (no DB write): rake scraping:test[123]"
  task :test, [ :scraped_url_id ] => :environment do |t, args|
    scraped_url = ScrapedUrl.find(args[:scraped_url_id])

    puts "\n=== DRY-RUN TEST: #{scraped_url.url} ==="
    puts "Notes correctrices: #{scraped_url.notes_correctrices.presence || "(none)"}"
    puts "\nFetching HTML..."

    scraper = ScrapingEngine.detect_scraper(scraped_url.url)

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
      puts "Prix: #{event[:prix_normal]}€#{event[:prix_reduit] ? " (réduit: #{event[:prix_reduit]}€)" : ""}"
      puts "Type: #{event[:type_event]}"
      puts "Tags: #{event[:tags].join(", ")}"
    end

    puts "\n=== DRY-RUN COMPLETED (no DB changes) ==="
  end
end
