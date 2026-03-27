require "playwright"

module Scrapers
  class PlaywrightScraper
    USER_AGENT = "stopand.dance bot - contact@stopand.dance"

    def self.fetch(url)
      # Launch Playwright browser (Chromium headless)
      Playwright.create(playwright_cli_executable_path: "./node_modules/.bin/playwright") do |playwright|
        playwright.chromium.launch(headless: true) do |browser|
          context = browser.new_context(
            user_agent: USER_AGENT,
            viewport: { width: 1920, height: 1080 }
          )

          page = context.new_page

          begin
            # Navigate to URL with 60s timeout
            page.goto(url, wait_until: "networkidle", timeout: 60_000)

            # Wait for JavaScript to fully execute
            page.wait_for_timeout(2000) # 2s additional wait for lazy-loaded content

            # Scroll to bottom to trigger lazy-loading
            page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            page.wait_for_timeout(1000)

            # Get final HTML after JS execution
            html = page.content

            {
              html: html,
              status: 200,
              content_type: "text/html",
              method: "playwright"
            }
          rescue Playwright::TimeoutError => e
            {
              error: "Playwright timeout: #{e.message}",
              status: nil
            }
          rescue StandardError => e
            {
              error: "Playwright error: #{e.message}",
              status: nil
            }
          ensure
            page.close
            context.close
          end
        end
      end
    rescue StandardError => e
      {
        error: "Playwright launch failed: #{e.message}",
        status: nil
      }
    end
  end
end
