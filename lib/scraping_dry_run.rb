class ScrapingDryRun
  # Runs the full scraping pipeline on all active ScrapedUrls without writing to DB.
  # Steps: fetch HTML → clean/convert to Markdown → return status per URL.
  # Does NOT call Claude CLI (too slow, out of scope for dry-run).
  # Returns array of { url_id, url, nom, success, error, html_size, markdown_size, duration_ms }

  MIN_MARKDOWN_SIZE = 300 # Below this, content is likely JS-only or placeholder

  def self.run_all
    ScrapedUrl.where(statut_scraping: "actif").map { |su| run_one(su) }
  end

  def self.run_one(scraped_url)
    result = {
      url_id: scraped_url.id, url: scraped_url.url, nom: scraped_url.nom,
      success: false, error: nil, html_size: 0, markdown_size: 0, duration_ms: 0
    }
    start = Time.current

    # Step 1 : Fetch HTML (Playwright if use_browser, else HtmlScraper)
    scraper = scraped_url.use_browser ? Scrapers::PlaywrightScraper : Scrapers::HtmlScraper
    fetch = scraper.fetch(scraped_url.url)

    if fetch[:error]
      result[:error] = "Fetch failed: #{fetch[:error].to_s.lines.first&.strip}"
      result[:duration_ms] = ((Time.current - start) * 1000).round
      return result
    end

    result[:html_size] = fetch[:html].to_s.bytesize

    # Step 2 : Clean HTML + convert to Markdown
    cleaned = HtmlCleaner.clean_and_convert(fetch[:html])
    result[:markdown_size] = cleaned[:markdown].to_s.bytesize

    if result[:markdown_size] < MIN_MARKDOWN_SIZE
      result[:error] = "Markdown too small (#{result[:markdown_size]} bytes, min #{MIN_MARKDOWN_SIZE}) — likely JS-only or empty"
      result[:duration_ms] = ((Time.current - start) * 1000).round
      return result
    end

    result[:success] = true
    result[:duration_ms] = ((Time.current - start) * 1000).round
    result
  rescue => e
    result[:error] = "Exception: #{e.class}: #{e.message}"
    result[:duration_ms] = ((Time.current - start) * 1000).round
    result
  end

  def self.print_report(results)
    total_duration = results.sum { |r| r[:duration_ms] || 0 }

    puts "=" * 70
    puts "SCRAPING DRY RUN REPORT"
    puts "=" * 70
    puts "Total URLs:     #{results.size}"
    puts "✅ Success:     #{results.count { |r| r[:success] }}"
    puts "❌ Failed:      #{results.count { |r| !r[:success] }}"
    puts "Total duration: #{(total_duration / 1000.0).round(1)}s"
    puts "=" * 70

    results.each do |r|
      status = r[:success] ? "✅" : "❌"
      label = r[:nom].presence || r[:url].to_s.truncate(60)
      duration = r[:duration_ms] ? " (#{r[:duration_ms]}ms)" : ""
      puts "#{status} ##{r[:url_id]} #{label}#{duration}"
      if r[:success]
        puts "   html=#{format_bytes(r[:html_size])} md=#{format_bytes(r[:markdown_size])}"
      else
        puts "   ERROR: #{r[:error]}"
      end
    end

    puts "=" * 70
    results
  end

  def self.format_bytes(bytes)
    return "#{bytes}B" if bytes < 1024
    "#{(bytes / 1024.0).round(1)}KB"
  end
end
