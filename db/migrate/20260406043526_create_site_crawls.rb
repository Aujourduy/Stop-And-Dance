class CreateSiteCrawls < ActiveRecord::Migration[8.1]
  def change
    create_table :site_crawls do |t|
      t.references :scraped_url, null: false, foreign_key: true
      t.datetime :started_at
      t.datetime :finished_at
      t.string :statut, null: false, default: "pending"
      t.integer :pages_found, default: 0
      t.integer :pages_classified_yes, default: 0
      t.integer :pages_classified_no, default: 0
      t.string :llm_model_used
      t.text :error_message

      t.timestamps
    end
  end
end
