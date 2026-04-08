class AddAcronymesToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :acronymes_preserves, :text, default: "CI, BMC, DJ, MC, NYC, USA"
  end
end
