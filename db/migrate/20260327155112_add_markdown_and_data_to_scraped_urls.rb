class AddMarkdownAndDataToScrapedUrls < ActiveRecord::Migration[8.1]
  def change
    add_column :scraped_urls, :derniere_version_markdown, :text
    add_column :scraped_urls, :data_attributes, :jsonb, default: {}, null: false
    add_column :scraped_urls, :html_hash, :string

    add_index :scraped_urls, :html_hash
  end
end
