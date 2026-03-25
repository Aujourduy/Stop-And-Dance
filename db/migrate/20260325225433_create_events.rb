class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :titre, null: false
      t.text :description
      t.string :tags, array: true, default: []
      t.timestamptz :date_debut, null: false
      t.timestamptz :date_fin, null: false
      t.integer :duree_minutes
      t.string :lieu
      t.text :adresse_complete
      t.decimal :prix_normal, precision: 8, scale: 2
      t.decimal :prix_reduit, precision: 8, scale: 2
      t.integer :type_event
      t.boolean :gratuit, default: false
      t.boolean :en_ligne, default: false
      t.boolean :en_presentiel, default: true
      t.references :professor, null: false, foreign_key: true
      t.references :scraped_url, null: true, foreign_key: true
      t.string :photo_url
      t.string :slug

      t.timestamps
    end
    add_index :events, :slug, unique: true
    add_index :events, :date_debut
    add_index :events, :gratuit
    add_index :events, :type_event
  end
end
