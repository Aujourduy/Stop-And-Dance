class CreateEventParticipations < ActiveRecord::Migration[8.1]
  def change
    create_table :event_participations do |t|
      t.references :event, null: false, foreign_key: { on_delete: :cascade }
      t.references :professor, null: false, foreign_key: { on_delete: :cascade }
      t.string :role
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :event_participations, [ :event_id, :professor_id ], unique: true
    add_index :event_participations, [ :event_id, :position ]

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO event_participations (event_id, professor_id, position, created_at, updated_at)
          SELECT id, professor_id, 0, NOW(), NOW()
          FROM events
          WHERE professor_id IS NOT NULL
        SQL
      end
    end

    change_column_null :events, :professor_id, true
  end
end
