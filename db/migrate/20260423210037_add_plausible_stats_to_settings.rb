class AddPlausibleStatsToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :plausible_api_key, :string
    add_column :settings, :plausible_site_id, :string
    add_column :settings, :stats_visits_7d, :integer
    add_column :settings, :stats_visitors_7d, :integer
    add_column :settings, :stats_updated_at, :datetime
  end
end
