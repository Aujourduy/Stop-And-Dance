class AddOpenrouterConfigToSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :settings, :openrouter_default_model, :string, default: "meta-llama/llama-3.3-70b-instruct:free"
  end
end
