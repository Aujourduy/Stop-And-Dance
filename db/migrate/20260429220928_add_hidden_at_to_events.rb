class AddHiddenAtToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :hidden_at, :datetime
    add_index :events, :hidden_at
  end
end
