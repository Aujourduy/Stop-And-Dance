# Timezone Configuration
# Europe/Paris display, UTC storage (Rails default)

Rails.application.configure do
  # Application timezone for displaying dates to users
  config.time_zone = "Europe/Paris"

  # IMPORTANT: garder :utc en base (défaut Rails).
  # Rails convertit automatiquement vers Europe/Paris à l'affichage
  # grâce à config.time_zone ci-dessus.
  # Stocker en local causerait des bugs aux changements d'heure été/hiver
  # (heure existe 2x en octobre, n'existe pas en mars).
  config.active_record.default_timezone = :utc
end

# Usage in models:
# - Use Time.zone.parse() for parsing user input
# - Event dates automatically display in Europe/Paris timezone
# - Database stores all timestamps in UTC
