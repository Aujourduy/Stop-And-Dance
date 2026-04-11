require "test_helper"

class ScrapingDryRunTest < ActiveSupport::TestCase
  # Helper : read fixture file
  def fixture_html(name)
    File.read(Rails.root.join("test/fixtures/files/scraping/#{name}.html"))
  end

  # Helper : temporarily override fetch on a scraper class
  def with_fetch_stub(klass, response)
    original = klass.method(:fetch)
    klass.define_singleton_method(:fetch) { |_url| response }
    yield
  ensure
    klass.define_singleton_method(:fetch, &original)
  end

  # Helper : stub scraper with html or error
  def stub_scraper(html:, use_browser: false, error: nil)
    klass = use_browser ? Scrapers::PlaywrightScraper : Scrapers::HtmlScraper
    response = error ? { error: error, status: nil } : { html: html, status: 200, content_type: "text/html" }
    with_fetch_stub(klass, response) { yield }
  end

  def make_url(attrs = {})
    prof = Professor.create!(nom: "Test #{attrs[:nom] || 'A'}")
    url = ScrapedUrl.create!(
      url: "https://example-test#{attrs[:id] || rand(10000)}.com/agenda",
      nom: attrs[:nom] || "Test",
      statut_scraping: "actif",
      use_browser: attrs[:use_browser] || false
    )
    url.professors << prof
    url
  end

  # --- run_one ---

  test "run_one succeeds on static HTML site" do
    scraped_url = make_url(nom: "Static")
    stub_scraper(html: fixture_html("static_site")) do
      result = ScrapingDryRun.run_one(scraped_url)
      assert result[:success], "Expected success but got error: #{result[:error]}"
      assert_nil result[:error]
      assert result[:html_size] > 100
      assert result[:markdown_size] > 100
      assert_equal scraped_url.id, result[:url_id]
    end
  end

  test "run_one succeeds on Wix site with enough content" do
    scraped_url = make_url(nom: "Wix", use_browser: true)
    stub_scraper(html: fixture_html("wix_site"), use_browser: true) do
      result = ScrapingDryRun.run_one(scraped_url)
      assert result[:success], "Expected success but got error: #{result[:error]}"
      assert result[:markdown_size] > 100
    end
  end

  test "run_one fails on React SPA empty body (JS-only)" do
    scraped_url = make_url(nom: "React")
    stub_scraper(html: fixture_html("react_empty")) do
      result = ScrapingDryRun.run_one(scraped_url)
      assert_not result[:success]
      assert_match(/Empty markdown/, result[:error])
    end
  end

  test "run_one captures fetch error" do
    scraped_url = make_url(nom: "Error")
    stub_scraper(html: nil, error: "Connection refused") do
      result = ScrapingDryRun.run_one(scraped_url)
      assert_not result[:success]
      assert_match(/Fetch failed/, result[:error])
      assert_match(/Connection refused/, result[:error])
    end
  end

  test "run_one captures exception" do
    scraped_url = make_url(nom: "Exception")
    klass = Scrapers::HtmlScraper
    original = klass.method(:fetch)
    klass.define_singleton_method(:fetch) { |_url| raise StandardError, "Network down" }
    begin
      result = ScrapingDryRun.run_one(scraped_url)
      assert_not result[:success]
      assert_match(/Exception.*Network down/, result[:error])
    ensure
      klass.define_singleton_method(:fetch, &original)
    end
  end

  test "run_one uses PlaywrightScraper when use_browser=true" do
    scraped_url = make_url(nom: "PW", use_browser: true)
    called = nil
    stub_response = { html: fixture_html("static_site"), status: 200 }

    pw_original = Scrapers::PlaywrightScraper.method(:fetch)
    ht_original = Scrapers::HtmlScraper.method(:fetch)
    Scrapers::PlaywrightScraper.define_singleton_method(:fetch) { |_url| called = :playwright; stub_response }
    Scrapers::HtmlScraper.define_singleton_method(:fetch) { |_url| called = :httparty; stub_response }
    begin
      ScrapingDryRun.run_one(scraped_url)
    ensure
      Scrapers::PlaywrightScraper.define_singleton_method(:fetch, &pw_original)
      Scrapers::HtmlScraper.define_singleton_method(:fetch, &ht_original)
    end
    assert_equal :playwright, called
  end

  test "run_one uses HtmlScraper when use_browser=false" do
    scraped_url = make_url(nom: "HT", use_browser: false)
    called = nil
    klass = Scrapers::HtmlScraper
    original = klass.method(:fetch)
    klass.define_singleton_method(:fetch) { |_url| called = :httparty; { html: File.read(Rails.root.join("test/fixtures/files/scraping/static_site.html")), status: 200 } }
    begin
      ScrapingDryRun.run_one(scraped_url)
    ensure
      klass.define_singleton_method(:fetch, &original)
    end
    assert_equal :httparty, called
  end

  # --- run_all ---

  test "run_all returns results for all active URLs" do
    make_url(nom: "Active 1")
    make_url(nom: "Active 2")
    inactive = make_url(nom: "Inactive")
    inactive.update!(statut_scraping: "pause")

    stub_scraper(html: fixture_html("static_site")) do
      results = ScrapingDryRun.run_all
      active_count = ScrapedUrl.where(statut_scraping: "actif").count
      assert_equal active_count, results.size
      # Inactive URL should not be in results
      assert_not results.map { |r| r[:url_id] }.include?(inactive.id)
    end
  end

  # --- does NOT write to DB ---

  test "run_one does not create events" do
    scraped_url = make_url(nom: "NoWrite")
    events_before = Event.count
    stub_scraper(html: fixture_html("static_site")) do
      ScrapingDryRun.run_one(scraped_url)
    end
    assert_equal events_before, Event.count
  end

  test "run_one does not touch scraped_url html fields" do
    scraped_url = make_url(nom: "NoTouch")
    assert_nil scraped_url.derniere_version_html
    stub_scraper(html: fixture_html("static_site")) do
      ScrapingDryRun.run_one(scraped_url)
    end
    assert_nil scraped_url.reload.derniere_version_html
  end

  # --- print_report ---

  test "print_report outputs summary and per-URL status" do
    results = [
      { url_id: 1, url: "https://a.com", nom: "Site A", success: true, error: nil, html_size: 1024, markdown_size: 500 },
      { url_id: 2, url: "https://b.com", nom: "Site B", success: false, error: "Fetch failed: 404", html_size: 0, markdown_size: 0 }
    ]
    out, _err = capture_io do
      ScrapingDryRun.print_report(results)
    end
    assert_match(/Total URLs: 2/, out)
    assert_match(/Success: 1/, out)
    assert_match(/Failed:  1/, out)
    assert_match(/✅.*Site A/, out)
    assert_match(/❌.*Site B/, out)
    assert_match(/Fetch failed: 404/, out)
  end
end
