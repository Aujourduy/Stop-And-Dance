class EnableUnaccentExtension < ActiveRecord::Migration[8.1]
  # Active l'extension PostgreSQL "unaccent" pour permettre les recherches
  # insensibles aux accents (ex: "clement" trouve "Clément Léon").
  def change
    enable_extension "unaccent"
  end
end
