class AddClickSelectorToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :scraped_urls, :click_selector, :string
  end
end
