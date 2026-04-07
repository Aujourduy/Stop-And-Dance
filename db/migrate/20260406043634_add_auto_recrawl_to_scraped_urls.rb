class AddAutoRecrawlToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :scraped_urls, :auto_recrawl, :boolean, default: false, null: false
  end
end
