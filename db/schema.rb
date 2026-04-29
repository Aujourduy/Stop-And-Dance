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

ActiveRecord::Schema[8.1].define(version: 2026_04_29_220928) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_notifications", force: :cascade do |t|
    t.string "category", default: "info", null: false
    t.datetime "created_at", null: false
    t.text "message"
    t.jsonb "metadata", default: {}
    t.string "source"
    t.string "status", default: "non_lu", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_admin_notifications_on_category"
    t.index ["status"], name: "index_admin_notifications_on_status"
  end

  create_table "change_logs", force: :cascade do |t|
    t.jsonb "changements_detectes"
    t.datetime "created_at", null: false
    t.text "diff_html"
    t.bigint "scraped_url_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_change_logs_on_created_at"
    t.index ["scraped_url_id"], name: "index_change_logs_on_scraped_url_id"
  end

  create_table "crawled_pages", force: :cascade do |t|
    t.string "content_hash"
    t.datetime "created_at", null: false
    t.integer "depth", default: 0, null: false
    t.text "error_message"
    t.integer "http_status"
    t.boolean "llm_verdict"
    t.bigint "site_crawl_id", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["site_crawl_id", "url"], name: "index_crawled_pages_on_site_crawl_id_and_url", unique: true
    t.index ["site_crawl_id"], name: "index_crawled_pages_on_site_crawl_id"
  end

  create_table "event_participations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "position", default: 0, null: false
    t.bigint "professor_id", null: false
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["event_id", "position"], name: "index_event_participations_on_event_id_and_position"
    t.index ["event_id", "professor_id"], name: "index_event_participations_on_event_id_and_professor_id", unique: true
    t.index ["event_id"], name: "index_event_participations_on_event_id"
    t.index ["professor_id"], name: "index_event_participations_on_professor_id"
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
    t.date "date_debut_date"
    t.timestamptz "date_fin", null: false
    t.date "date_fin_date"
    t.text "description"
    t.integer "duree_minutes"
    t.boolean "en_ligne", default: false
    t.boolean "en_presentiel", default: true
    t.boolean "generated_from_recurrence", default: false, null: false
    t.boolean "gratuit", default: false
    t.time "heure_debut"
    t.time "heure_fin"
    t.datetime "hidden_at"
    t.string "lieu"
    t.string "photo_url"
    t.decimal "prix_normal", precision: 8, scale: 2
    t.decimal "prix_reduit", precision: 8, scale: 2
    t.bigint "professor_id"
    t.bigint "scraped_url_id"
    t.string "slug"
    t.string "tags", default: [], array: true
    t.string "titre", null: false
    t.integer "type_event"
    t.datetime "updated_at", null: false
    t.index ["date_debut"], name: "index_events_on_date_debut"
    t.index ["gratuit"], name: "index_events_on_gratuit"
    t.index ["hidden_at"], name: "index_events_on_hidden_at"
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
    t.string "prenom"
    t.string "site_web"
    t.string "status", default: "auto", null: false
    t.datetime "updated_at", null: false
    t.index ["nom_normalise"], name: "index_professors_on_nom_normalise", unique: true
  end

  create_table "scraped_urls", force: :cascade do |t|
    t.boolean "auto_recrawl", default: false, null: false
    t.string "avatar_url"
    t.string "click_selector"
    t.text "commentaire"
    t.datetime "created_at", null: false
    t.jsonb "data_attributes", default: {}, null: false
    t.datetime "dernier_parsing_claude_at"
    t.text "derniere_version_html"
    t.datetime "derniere_version_html_at"
    t.text "derniere_version_markdown"
    t.datetime "derniere_version_markdown_at"
    t.string "detail_link_selector"
    t.boolean "enrich_detail_pages", default: false, null: false
    t.integer "erreurs_consecutives", default: 0
    t.string "html_hash"
    t.string "nom"
    t.text "notes_correctrices"
    t.string "public_url"
    t.bigint "source_site_crawl_id"
    t.string "statut_scraping", default: "actif"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.boolean "use_browser", default: true, null: false
    t.index ["html_hash"], name: "index_scraped_urls_on_html_hash"
    t.index ["source_site_crawl_id"], name: "index_scraped_urls_on_source_site_crawl_id"
    t.index ["url"], name: "index_scraped_urls_on_url", unique: true
  end

  create_table "settings", force: :cascade do |t|
    t.text "acronymes_preserves", default: "CI, BMC, DJ, MC, NYC, USA"
    t.text "claude_global_instructions"
    t.datetime "created_at", null: false
    t.string "openrouter_default_model", default: "meta-llama/llama-3.3-70b-instruct:free"
    t.datetime "stats_updated_at"
    t.integer "stats_visitors_7d"
    t.integer "stats_visits_7d"
    t.datetime "updated_at", null: false
  end

  create_table "site_crawls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error_message"
    t.datetime "finished_at"
    t.string "llm_model_used"
    t.integer "pages_classified_no", default: 0
    t.integer "pages_classified_yes", default: 0
    t.integer "pages_found", default: 0
    t.bigint "scraped_url_id", null: false
    t.datetime "started_at"
    t.string "statut", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["scraped_url_id"], name: "index_site_crawls_on_scraped_url_id"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "change_logs", "scraped_urls"
  add_foreign_key "crawled_pages", "site_crawls"
  add_foreign_key "event_participations", "events", on_delete: :cascade
  add_foreign_key "event_participations", "professors", on_delete: :cascade
  add_foreign_key "event_sources", "events"
  add_foreign_key "event_sources", "scraped_urls"
  add_foreign_key "events", "professors"
  add_foreign_key "events", "scraped_urls"
  add_foreign_key "professor_scraped_urls", "professors"
  add_foreign_key "professor_scraped_urls", "scraped_urls"
  add_foreign_key "scraped_urls", "site_crawls", column: "source_site_crawl_id"
  add_foreign_key "site_crawls", "scraped_urls"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
