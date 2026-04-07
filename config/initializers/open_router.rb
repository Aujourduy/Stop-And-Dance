OPEN_ROUTER_CONFIG = {
  api_key: ENV.fetch("OPENROUTER_API_KEY", nil),
  base_url: "https://openrouter.ai/api/v1",
  timeout: ENV.fetch("OPENROUTER_TIMEOUT", "30").to_i,
  rate_limit_sleep: ENV.fetch("OPENROUTER_RATE_LIMIT_SLEEP", "3").to_i
}.freeze
