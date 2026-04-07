class CreateCrawledPages < ActiveRecord::Migration[8.1]
  def change
    create_table :crawled_pages do |t|
      t.references :site_crawl, null: false, foreign_key: true
      t.string :url, null: false
      t.integer :depth, null: false, default: 0
      t.string :content_hash
      t.boolean :llm_verdict
      t.integer :http_status
      t.text :error_message

      t.timestamps
    end
    add_index :crawled_pages, [:site_crawl_id, :url], unique: true
  end
end
