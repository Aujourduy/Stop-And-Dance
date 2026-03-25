class CreateNewsletters < ActiveRecord::Migration[8.1]
  def change
    create_table :newsletters do |t|
      t.string :email, null: false
      t.timestamp :consenti_at
      t.boolean :actif, default: true

      t.timestamps
    end
    add_index :newsletters, :email, unique: true
  end
end
