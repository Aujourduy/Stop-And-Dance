class AddEnrichDetailPagesToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :scraped_urls, :enrich_detail_pages, :boolean, default: false, null: false
    add_column :scraped_urls, :detail_link_selector, :string
  end
end
