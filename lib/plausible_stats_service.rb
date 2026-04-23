require "net/http"
require "json"

# Fetch des stats depuis l'API Plausible self-hosted et mise en cache
# dans Setting (singleton). Appelé périodiquement par UpdateStatsJob
# (toutes les 15 minutes via cron Solid Queue).
#
# Endpoint : GET {base}/api/v1/stats/aggregate?site_id=X&period=7d&metrics=visits,visitors
# Auth : Bearer token API (créé dans le dashboard Plausible)
class PlausibleStatsService
  BASE_URL = "https://stats.stopand.dance".freeze
  PERIOD = "7d".freeze

  def self.fetch_and_cache
    setting = Setting.instance
    return { error: "No API key" } if setting.plausible_api_key.blank?
    return { error: "No site ID" } if setting.plausible_site_id.blank?

    uri = URI("#{BASE_URL}/api/v1/stats/aggregate")
    uri.query = URI.encode_www_form(
      site_id: setting.plausible_site_id,
      period: PERIOD,
      metrics: "visits,visitors"
    )

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{setting.plausible_api_key}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    response = http.request(req)
    return { error: "HTTP #{response.code}: #{response.body[0..200]}" } unless response.code == "200"

    data = JSON.parse(response.body).dig("results") || {}
    visits = data.dig("visits", "value").to_i
    visitors = data.dig("visitors", "value").to_i

    setting.update!(
      stats_visits_7d: visits,
      stats_visitors_7d: visitors,
      stats_updated_at: Time.current
    )

    { visits: visits, visitors: visitors }
  rescue StandardError => e
    Rails.logger.error("PlausibleStatsService error: #{e.message}")
    { error: e.message }
  end
end
