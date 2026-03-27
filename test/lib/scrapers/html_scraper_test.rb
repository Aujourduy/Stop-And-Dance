require "test_helper"

class HtmlScraperTest < ActiveSupport::TestCase
  test "fetches HTML successfully from valid URL" do
    result = Scrapers::HtmlScraper.fetch("https://example.com")

    assert result[:html].present?
    assert_equal 200, result[:status]
    assert result[:content_type].present?
  end

  test "returns error for 404 URLs" do
    result = Scrapers::HtmlScraper.fetch("https://example.com/nonexistent")

    assert result[:error].present?
    assert_equal 404, result[:status]
  end

  test "uses correct user agent" do
    assert_equal "stopand.dance bot - contact@stopand.dance",
                 Scrapers::HtmlScraper::USER_AGENT
  end

  test "handles network errors gracefully" do
    result = Scrapers::HtmlScraper.fetch("https://invalid-domain-12345.com")

    assert result[:error].present?
  end
end
