class UpdateStatsJob < ApplicationJob
  queue_as :default

  def perform
    result = PlausibleStatsService.fetch_and_cache
    if result[:error]
      Rails.logger.warn("UpdateStatsJob: #{result[:error]}")
    else
      Rails.logger.info("UpdateStatsJob: #{result[:visits]} visits / #{result[:visitors]} visitors (7d)")
    end
  end
end
