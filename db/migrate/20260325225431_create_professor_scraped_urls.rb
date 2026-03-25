class CreateProfessorScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    create_table :professor_scraped_urls do |t|
      t.references :professor, null: false, foreign_key: true, index: true
      t.references :scraped_url, null: false, foreign_key: true, index: true

      t.timestamps
    end
  end
end
