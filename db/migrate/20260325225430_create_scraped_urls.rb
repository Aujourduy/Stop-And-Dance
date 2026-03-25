class CreateScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :scraped_urls do |t|
      t.string :url, null: false
      t.text :notes_correctrices
      t.text :derniere_version_html
      t.string :statut_scraping, default: 'actif'
      t.integer :erreurs_consecutives, default: 0

      t.timestamps
    end
    add_index :scraped_urls, :url, unique: true
  end
end
