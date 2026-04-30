class SiteCrawler
  MAX_DEPTH = 5
  MAX_PAGES = 100

  def initialize(scraped_url, llm_model: nil)
    @scraped_url = scraped_url
    @llm_model = llm_model || Setting.instance.openrouter_default_model
    @root_uri = URI.parse(scraped_url.url)
    @root_host = @root_uri.host
  end

  def crawl!
    @site_crawl = SiteCrawl.create!(
      scraped_url: @scraped_url,
      statut: "running",
      started_at: Time.current,
      llm_model_used: @llm_model
    )

    SCRAPING_LOGGER.info({ event: "site_crawl_started", scraped_url_id: @scraped_url.id, root_url: @scraped_url.url }.to_json)

    visited = Set.new
    queue = [ { url: normalize_url(@scraped_url.url), depth: 0 } ]
    pages_count = 0

    while queue.any? && pages_count < MAX_PAGES
      item = queue.shift
      url = item[:url]
      depth = item[:depth]

      next if visited.include?(url)
      next if depth > MAX_DEPTH
      next unless same_domain?(url)

      visited.add(url)
      pages_count += 1

      page, html = crawl_page(url, depth)

      if html.present? && page.error_message.blank?
        extract_links(url, html).each do |link|
          queue.push({ url: link, depth: depth + 1 }) unless visited.include?(link)
        end
      end
    end

    create_scraped_urls_for_yes_pages
    finalize_crawl

    SCRAPING_LOGGER.info({
      event: "site_crawl_completed",
      site_crawl_id: @site_crawl.id,
      pages_found: @site_crawl.pages_found,
      pages_classified_yes: @site_crawl.pages_classified_yes
    }.to_json)

    @site_crawl
  rescue => e
    @site_crawl&.update!(statut: "failed", finished_at: Time.current, error_message: e.message)
    SCRAPING_LOGGER.error({ event: "site_crawl_failed", site_crawl_id: @site_crawl&.id, error: e.message }.to_json)
    raise
  end

  private

  MIN_VISIBLE_TEXT = 500

  EVENT_URL_KEYWORDS = %w[
    agenda agendas stage stages atelier ateliers date dates event events evenement evenements
    evenement evènement evènements événement événements calendrier programme programmes
    workshop workshops retraite retraites cours seminaire seminaires séminaire séminaires
    formation formations actualite actualites actualité actualités prochain prochains
  ].freeze

  def event_candidate_url?(url)
    path = (URI.parse(url).path || "").downcase
    return true if path == "" || path == "/"
    EVENT_URL_KEYWORDS.any? { |kw| path.include?(kw) }
  rescue URI::InvalidURIError
    false
  end

  def crawl_page(url, depth)
    # Try HTTParty first (fast), fallback to Playwright if JS-only content detected
    result = Scrapers::HtmlScraper.fetch(url)

    if result[:error]
      page = @site_crawl.crawled_pages.create!(
        url: url, depth: depth, http_status: result[:status],
        error_message: result[:error]
      )
      return [ page, nil ]
    end

    html = result[:html]

    # Detect JS-only pages: if visible text < threshold, retry with Playwright
    if js_only_content?(html)
      SCRAPING_LOGGER.info({ event: "js_only_detected", url: url, fallback: "playwright" }.to_json)
      pw_result = Scrapers::PlaywrightScraper.fetch(url)
      html = pw_result[:html] if pw_result[:html].present? && !pw_result[:error]
    end

    content_hash = Digest::SHA256.hexdigest(html)

    # Heuristique URL : ne classifier au LLM que les URLs candidates
    # (racine + URLs avec mots-clés d'event). Économise le quota free tier.
    if event_candidate_url?(url)
      cleaned = HtmlCleaner.clean_and_convert(html)
      classification = OpenRouterClassifier.classify(markdown: cleaned[:markdown], model: @llm_model)
      verdict = classification[:verdict]
      error = classification[:error]
    else
      verdict = "no"
      error = nil
    end

    page = @site_crawl.crawled_pages.create!(
      url: url, depth: depth, content_hash: content_hash,
      http_status: result[:status] || 200,
      llm_verdict: verdict,
      error_message: error
    )
    [ page, html ]
  rescue => e
    SCRAPING_LOGGER.error({ event: "page_crawl_error", url: url, error: e.message }.to_json)
    page = @site_crawl.crawled_pages.create!(
      url: url, depth: depth, error_message: e.message
    )
    [ page, nil ]
  end

  def extract_links(base_url, html)
    doc = Nokogiri::HTML(html)
    links = []

    doc.css("a[href]").each do |a|
      href = a["href"].to_s.strip
      next if href.empty? || href.start_with?("#", "mailto:", "tel:", "javascript:")

      begin
        absolute = URI.join(base_url, href).to_s
        normalized = normalize_url(absolute)
        links << normalized if same_domain?(normalized)
      rescue URI::InvalidURIError
        next
      end
    end

    links.uniq
  end

  def js_only_content?(html)
    doc = Nokogiri::HTML(html)

    # Check noscript tag for "enable javascript" message
    noscript = doc.css("noscript").text.downcase
    return true if noscript.match?(/javascript|enable|activer/)

    # Check visible text length
    doc.css("script, style, noscript, meta, link, svg").remove
    visible_text = doc.text.gsub(/\s+/, " ").strip
    visible_text.length < MIN_VISIBLE_TEXT
  end

  def same_domain?(url)
    URI.parse(url).host == @root_host
  rescue URI::InvalidURIError
    false
  end

  def normalize_url(url)
    uri = URI.parse(url)
    uri.fragment = nil
    uri.to_s.chomp("/")
  rescue URI::InvalidURIError
    url
  end

  def create_scraped_urls_for_yes_pages
    @site_crawl.crawled_pages.classified_yes.each do |page|
      next if ScrapedUrl.exists?(url: page.url)

      new_scraped_url = ScrapedUrl.create!(
        url: page.url,
        nom: "Auto-crawl: #{URI.parse(page.url).host}",
        use_browser: @scraped_url.use_browser,
        statut_scraping: "actif",
        source_site_crawl: @site_crawl
      )

      @scraped_url.professors.each do |prof|
        ProfessorScrapedUrl.find_or_create_by!(professor: prof, scraped_url: new_scraped_url)
      end

      SCRAPING_LOGGER.info({ event: "auto_scraped_url_created", url: page.url, site_crawl_id: @site_crawl.id }.to_json)
    end
  end

  def finalize_crawl
    @site_crawl.update!(
      statut: "completed",
      finished_at: Time.current,
      pages_found: @site_crawl.crawled_pages.count,
      pages_classified_yes: @site_crawl.crawled_pages.classified_yes.count,
      pages_classified_no: @site_crawl.crawled_pages.classified_no.count
    )
  end
end
