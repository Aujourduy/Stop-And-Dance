# Scraping Logger for structured JSON logging
# All scraping activities logged to log/scraping.log

log_path = Rails.root.join("log", "scraping.log")
SCRAPING_LOGGER = Logger.new(log_path, 5, 10.megabytes)
SCRAPING_LOGGER.level = Logger::INFO
SCRAPING_LOGGER.formatter = proc do |severity, datetime, progname, msg|
  # JSON formatting for easy parsing
  {
    timestamp: datetime.iso8601,
    severity: severity,
    message: msg
  }.to_json + "\n"
end
