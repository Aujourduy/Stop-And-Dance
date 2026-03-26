require "test_helper"
require "capybara/playwright"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright, using: :chromium, screen_size: [ 1400, 1400 ], options: {
    headless: true,
    playwright_cli_executable_path: "./node_modules/.bin/playwright"
  }

  # Let Capybara choose an available port automatically
  Capybara.server_host = "127.0.0.1"
  Capybara.server = :puma, { Silent: true }
end
