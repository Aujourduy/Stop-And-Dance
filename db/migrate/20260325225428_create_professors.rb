class CreateProfessors < ActiveRecord::Migration[8.1]
  def change
    create_table :professors do |t|
      t.string :avatar_url
      t.text :bio
      t.string :site_web
      t.string :email
      t.integer :consultations_count, default: 0
      t.integer :clics_sortants_count, default: 0

      t.timestamps
    end
  end
end
