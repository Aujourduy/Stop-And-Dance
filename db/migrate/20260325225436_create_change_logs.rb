class CreateChangeLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :change_logs do |t|
      t.text :diff_html
      t.jsonb :changements_detectes
      t.references :scraped_url, null: false, foreign_key: true, index: true

      t.timestamps
    end
    add_index :change_logs, :created_at
  end
end
