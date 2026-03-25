class CreateEventSources < ActiveRecord::Migration[8.1]
  def change
    create_table :event_sources do |t|
      t.references :event, null: false, foreign_key: true
      t.references :scraped_url, null: false, foreign_key: true
      t.boolean :primary_source, default: false

      t.timestamps
    end
    add_index :event_sources, [:event_id, :scraped_url_id], unique: true
  end
end
