class AddSourceSiteCrawlToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_reference :scraped_urls, :source_site_crawl, null: true, foreign_key: { to_table: :site_crawls }
  end
end
