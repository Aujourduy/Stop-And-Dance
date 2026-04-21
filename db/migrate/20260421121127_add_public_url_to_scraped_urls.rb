class AddPublicUrlToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :scraped_urls, :public_url, :string
  end
end
