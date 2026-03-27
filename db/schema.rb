# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_27_155112) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "change_logs", force: :cascade do |t|
    t.jsonb "changements_detectes"
    t.datetime "created_at", null: false
    t.text "diff_html"
    t.bigint "scraped_url_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_change_logs_on_created_at"
    t.index ["scraped_url_id"], name: "index_change_logs_on_scraped_url_id"
  end

  create_table "event_sources", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.boolean "primary_source", default: false
    t.bigint "scraped_url_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "scraped_url_id"], name: "index_event_sources_on_event_id_and_scraped_url_id", unique: true
    t.index ["event_id"], name: "index_event_sources_on_event_id"
    t.index ["scraped_url_id"], name: "index_event_sources_on_scraped_url_id"
  end

  create_table "events", force: :cascade do |t|
    t.text "adresse_complete"
    t.datetime "created_at", null: false
    t.timestamptz "date_debut", null: false
    t.timestamptz "date_fin", null: false
    t.text "description"
    t.integer "duree_minutes"
    t.boolean "en_ligne", default: false
    t.boolean "en_presentiel", default: true
    t.boolean "gratuit", default: false
    t.string "lieu"
    t.string "photo_url"
    t.decimal "prix_normal", precision: 8, scale: 2
    t.decimal "prix_reduit", precision: 8, scale: 2
    t.bigint "professor_id", null: false
    t.bigint "scraped_url_id"
    t.string "slug"
    t.string "tags", default: [], array: true
    t.string "titre", null: false
    t.integer "type_event"
    t.datetime "updated_at", null: false
    t.index ["date_debut"], name: "index_events_on_date_debut"
    t.index ["gratuit"], name: "index_events_on_gratuit"
    t.index ["professor_id"], name: "index_events_on_professor_id"
    t.index ["scraped_url_id"], name: "index_events_on_scraped_url_id"
    t.index ["slug"], name: "index_events_on_slug", unique: true
    t.index ["type_event"], name: "index_events_on_type_event"
  end

  create_table "newsletters", force: :cascade do |t|
    t.boolean "actif", default: true
    t.datetime "consenti_at", precision: nil
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_newsletters_on_email", unique: true
  end

  create_table "professor_scraped_urls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "professor_id", null: false
    t.bigint "scraped_url_id", null: false
    t.datetime "updated_at", null: false
    t.index ["professor_id"], name: "index_professor_scraped_urls_on_professor_id"
    t.index ["scraped_url_id"], name: "index_professor_scraped_urls_on_scraped_url_id"
  end

  create_table "professors", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.integer "clics_sortants_count", default: 0
    t.integer "consultations_count", default: 0
    t.datetime "created_at", null: false
    t.string "email"
    t.string "nom"
    t.string "nom_normalise"
    t.string "site_web"
    t.string "status", default: "auto", null: false
    t.datetime "updated_at", null: false
    t.index ["nom_normalise"], name: "index_professors_on_nom_normalise", unique: true
  end

  create_table "scraped_urls", force: :cascade do |t|
    t.text "commentaire"
    t.datetime "created_at", null: false
    t.jsonb "data_attributes", default: {}, null: false
    t.text "derniere_version_html"
    t.text "derniere_version_markdown"
    t.integer "erreurs_consecutives", default: 0
    t.string "html_hash"
    t.string "nom"
    t.text "notes_correctrices"
    t.string "statut_scraping", default: "actif"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.boolean "use_browser", default: true, null: false
    t.index ["html_hash"], name: "index_scraped_urls_on_html_hash"
    t.index ["url"], name: "index_scraped_urls_on_url", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.text "claude_global_instructions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "change_logs", "scraped_urls"
  add_foreign_key "event_sources", "events"
  add_foreign_key "event_sources", "scraped_urls"
  add_foreign_key "events", "professors"
  add_foreign_key "events", "scraped_urls"
  add_foreign_key "professor_scraped_urls", "professors"
  add_foreign_key "professor_scraped_urls", "scraped_urls"
end
