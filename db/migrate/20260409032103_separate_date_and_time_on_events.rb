class SeparateDateAndTimeOnEvents < ActiveRecord::Migration[8.1]
  def up
    # Add new columns
    add_column :events, :date_debut_date, :date
    add_column :events, :date_fin_date, :date
    add_column :events, :heure_debut, :time
    add_column :events, :heure_fin, :time

    # Migrate existing data
    execute <<-SQL
      UPDATE events
      SET date_debut_date = date_debut::date,
          date_fin_date = date_fin::date,
          heure_debut = date_debut::time,
          heure_fin = date_fin::time
      WHERE date_debut IS NOT NULL
    SQL
  end

  def down
    remove_column :events, :date_debut_date
    remove_column :events, :date_fin_date
    remove_column :events, :heure_debut
    remove_column :events, :heure_fin
  end
end
