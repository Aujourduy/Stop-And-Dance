class AddAvatarUrlToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :scraped_urls, :avatar_url, :string
  end
end
