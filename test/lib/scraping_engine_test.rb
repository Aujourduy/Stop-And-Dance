require "test_helper"

class ScrapingEngineTest < ActiveSupport::TestCase
  setup do
    @scraped_url = ScrapedUrl.create!(
      url: "https://example.com/test",
      statut_scraping: "actif",
      erreurs_consecutives: 0
    )
  end

  test "detects Playwright scraper when use_browser is true" do
    scraped_url = ScrapedUrl.create!(url: "https://example.com", use_browser: true)
    scraper = ScrapingEngine.detect_scraper(scraped_url)
    assert_equal Scrapers::PlaywrightScraper, scraper
  end

  test "detects HtmlScraper when use_browser is false" do
    scraped_url = ScrapedUrl.create!(url: "https://example.com", use_browser: false)
    scraper = ScrapingEngine.detect_scraper(scraped_url)
    assert_equal Scrapers::HtmlScraper, scraper
  end

  test "uses HtmlScraper by default for HTTParty-compatible sites" do
    scraped_url = ScrapedUrl.create!(url: "https://static-site.com", use_browser: false)
    scraper = ScrapingEngine.detect_scraper(scraped_url)
    assert_equal Scrapers::HtmlScraper, scraper
  end

  test "uses PlaywrightScraper for JavaScript-heavy sites" do
    scraped_url = ScrapedUrl.create!(url: "https://wix-site.com", use_browser: true)
    scraper = ScrapingEngine.detect_scraper(scraped_url)
    assert_equal Scrapers::PlaywrightScraper, scraper
  end

  test "increments error counter on scraping failure" do
    # Skip network-dependent test that can pollute transactions
    skip "Network error tests can cause PG transaction pollution"
  end

  test "resets error counter on successful scraping" do
    # Skip network-dependent integration test
    skip "Network tests require mocking or VCR for stable CI"
  end
end
