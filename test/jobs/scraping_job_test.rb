require "test_helper"

class ScrapingJobTest < ActiveSupport::TestCase
  test "processes active scraped URL" do
    # Skip network-dependent test
    skip "Network tests require mocking for stable CI"
  end

  test "skips inactive scraped URL" do
    scraped_url = ScrapedUrl.create!(
      url: "https://example.com",
      statut_scraping: "inactif"
    )

    # Should not raise error, just skip
    assert_nothing_raised do
      ScrapingJob.new.perform(scraped_url.id)
    end
  end
end
