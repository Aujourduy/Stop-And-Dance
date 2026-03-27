module Scrapers
  class HtmlScraper
    USER_AGENT = "stopand.dance bot - contact@stopand.dance"

    def self.fetch(url)
      # Check robots.txt compliance first (NFR-S1)
      return { error: "Disallowed by robots.txt" } unless robots_allowed?(url)

      response = HTTParty.get(
        url,
        headers: { "User-Agent" => USER_AGENT },
        timeout: 30,
        follow_redirects: true
      )

      if response.success?
        {
          html: response.body,
          status: response.code,
          content_type: response.headers["content-type"]
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
      # Use robots gem to check robots.txt
      # Returns true if bot is allowed to scrape this URL
      require "robots"
      robots = Robots.new(USER_AGENT)
      robots.allowed?(url)
    rescue
      # If robots.txt fetch fails, assume allowed (defensive approach)
      true
    end
  end
end
