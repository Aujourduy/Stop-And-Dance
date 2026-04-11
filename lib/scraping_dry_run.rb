class ScrapingDryRun
  # Runs the full scraping pipeline on all active ScrapedUrls without writing to DB.
  # Steps: fetch HTML → clean/convert to Markdown → return status per URL.
  # Does NOT call Claude CLI (too slow, out of scope for dry-run).
  # Returns array of { url_id, url, nom, success, error, html_size, markdown_size }

  def self.run_all
    ScrapedUrl.where(statut_scraping: "actif").map { |su| run_one(su) }
  end

  def self.run_one(scraped_url)
    result = { url_id: scraped_url.id, url: scraped_url.url, nom: scraped_url.nom, success: false, error: nil, html_size: 0, markdown_size: 0 }

    # Step 1 : Fetch HTML (Playwright by default for dry-run — robust on JS-heavy sites)
    scraper = scraped_url.use_browser ? Scrapers::PlaywrightScraper : Scrapers::HtmlScraper
    fetch = scraper.fetch(scraped_url.url)

    if fetch[:error]
      result[:error] = "Fetch failed: #{fetch[:error]}"
      return result
    end

    result[:html_size] = fetch[:html].to_s.bytesize

    # Step 2 : Clean HTML + convert to Markdown
    cleaned = HtmlCleaner.clean_and_convert(fetch[:html])
    result[:markdown_size] = cleaned[:markdown].to_s.bytesize

    if result[:markdown_size] < 100
      result[:error] = "Empty markdown after cleaning (#{result[:markdown_size]} bytes)"
      return result
    end

    result[:success] = true
    result
  rescue => e
    result[:error] = "Exception: #{e.class}: #{e.message}"
    result
  end

  def self.print_report(results)
    puts "=" * 70
    puts "SCRAPING DRY RUN REPORT"
    puts "=" * 70
    puts "Total URLs: #{results.size}"
    puts "✅ Success: #{results.count { |r| r[:success] }}"
    puts "❌ Failed:  #{results.count { |r| !r[:success] }}"
    puts "=" * 70

    results.each do |r|
      status = r[:success] ? "✅" : "❌"
      label = r[:nom].presence || r[:url].to_s.truncate(60)
      puts "#{status} ##{r[:url_id]} #{label}"
      if r[:success]
        puts "   html=#{r[:html_size]}B md=#{r[:markdown_size]}B"
      else
        puts "   ERROR: #{r[:error]}"
      end
    end

    puts "=" * 70
    results
  end
end
