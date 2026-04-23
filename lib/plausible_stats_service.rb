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

  def self.fetch_and_cache
    api_key = ENV["PLAUSIBLE_API_KEY"]
    site_id = ENV["PLAUSIBLE_SITE_ID"] || "stopand.dance"
    return { error: "No API key (set PLAUSIBLE_API_KEY)" } if api_key.blank?

    # Période custom = 7 derniers jours INCLUANT aujourd'hui
    # (le paramètre "7d" de Plausible exclut le jour courant → pas ce qu'on veut).
    today = Date.current
    from = today - 6
    date_range = "#{from.iso8601},#{today.iso8601}"

    uri = URI("#{BASE_URL}/api/v1/stats/aggregate")
    uri.query = URI.encode_www_form(
      site_id: site_id,
      period: "custom",
      date: date_range,
      metrics: "visits,visitors"
    )

    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{api_key}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.read_timeout = 10

    response = http.request(req)
    return { error: "HTTP #{response.code}: #{response.body[0..200]}" } unless response.code == "200"

    data = JSON.parse(response.body).dig("results") || {}
    visits = data.dig("visits", "value").to_i
    visitors = data.dig("visitors", "value").to_i

    Setting.instance.update!(
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
