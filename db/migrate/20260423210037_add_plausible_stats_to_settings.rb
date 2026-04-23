class AddPlausibleStatsToSettings < ActiveRecord::Migration[8.1]
  def change
    # Cache des stats 7j (rafraîchi par UpdateStatsJob toutes les 15 min).
    # Les credentials API (PLAUSIBLE_API_KEY, PLAUSIBLE_SITE_ID) sont en ENV.
    add_column :settings, :stats_visits_7d, :integer
    add_column :settings, :stats_visitors_7d, :integer
    add_column :settings, :stats_updated_at, :datetime
  end
end
