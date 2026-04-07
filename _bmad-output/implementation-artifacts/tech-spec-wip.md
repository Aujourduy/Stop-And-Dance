---
title: 'Crawler site prof avec détection LLM pages ateliers'
slug: 'crawler-site-prof-llm'
created: '2026-04-05'
status: 'review'
stepsCompleted: [1, 2, 3]
tech_stack:
  - 'Rails 8'
  - 'PostgreSQL (JSONB)'
  - 'Solid Queue'
  - 'HTTParty (déjà installé)'
  - 'Nokogiri (déjà installé)'
  - 'reverse_markdown (déjà installé)'
  - 'robots gem (déjà installée)'
  - 'OpenRouter API (nouveau, via HTTParty)'
  - 'WebMock (à ajouter pour tests)'
files_to_modify:
  - 'db/migrate/*_create_site_crawls.rb (nouveau)'
  - 'db/migrate/*_create_crawled_pages.rb (nouveau)'
  - 'db/migrate/*_add_openrouter_config_to_settings.rb (nouveau)'
  - 'db/migrate/*_add_auto_recrawl_to_scraped_urls.rb (nouveau)'
  - 'db/migrate/*_add_site_crawl_id_to_scraped_urls.rb (nouveau)'
  - 'app/models/site_crawl.rb (nouveau)'
  - 'app/models/crawled_page.rb (nouveau)'
  - 'app/models/setting.rb (modifier)'
  - 'app/models/scraped_url.rb (associations)'
  - 'lib/site_crawler.rb (nouveau)'
  - 'lib/open_router_classifier.rb (nouveau)'
  - 'app/jobs/site_crawl_job.rb (nouveau)'
  - 'app/jobs/site_crawl_dispatch_job.rb (nouveau recurring)'
  - 'app/controllers/admin/scraped_urls_controller.rb (action crawl_site)'
  - 'app/controllers/admin/site_crawls_controller.rb (nouveau)'
  - 'app/controllers/admin/settings_controller.rb (params)'
  - 'app/views/admin/scraped_urls/show.html.erb (bouton)'
  - 'app/views/admin/site_crawls/index.html.erb (nouveau)'
  - 'app/views/admin/site_crawls/show.html.erb (nouveau)'
  - 'app/views/admin/settings/edit.html.erb (champ modèle)'
  - 'config/routes.rb'
  - 'config/recurring.yml'
  - 'config/initializers/open_router.rb (nouveau)'
  - '.env.example'
  - 'Gemfile (webmock dev/test)'
  - 'test/models/site_crawl_test.rb (nouveau)'
  - 'test/models/crawled_page_test.rb (nouveau)'
  - 'test/jobs/site_crawl_job_test.rb (nouveau)'
  - 'test/jobs/site_crawl_dispatch_job_test.rb (nouveau)'
  - 'test/lib/site_crawler_test.rb (nouveau)'
  - 'test/lib/open_router_classifier_test.rb (nouveau)'
  - 'test/controllers/admin/scraped_urls_controller_test.rb (ajouter tests)'
  - 'test/controllers/admin/site_crawls_controller_test.rb (nouveau)'
code_patterns:
  - 'Jobs : queue_as :scraping, retry_on StandardError wait: :exponentially_longer attempts: 3'
  - 'Admin actions : member do post :action_name + button_to dans view'
  - 'Singleton Setting.instance pour config globale'
  - 'SCRAPING_LOGGER.info({event: "...", ...}.to_json)'
  - 'Pagy dans admin : @pagy, @records = pagy(scope)'
  - 'Strong params via params.require(...).permit(...)'
  - 'Services : classes dans lib/ avec méthodes de classe'
test_patterns:
  - 'Minitest + fixtures :all'
  - 'Tests jobs via assert_enqueued_with'
  - 'WebMock pour mocker HTTP externes'
---

# Tech-Spec: Crawler site prof avec détection LLM pages ateliers

**Created:** 2026-04-05

## Overview

### Problem Statement

Actuellement, chaque URL d'atelier doit être ajoutée manuellement via `/admin/scraped_urls`. Certains sites de profs ont plusieurs pages contenant des ateliers différents (ex: une page par discipline, par ville, ou par mois). L'admin doit visiter manuellement le site, identifier chaque page pertinente et la saisir une par une. C'est fastidieux, source d'oublis, et ne détecte pas automatiquement les nouvelles pages ajoutées par le prof.

### Solution

À partir d'une URL racine (site du prof) déjà présente dans `ScrapedUrl`, un crawler récursif visite le site (profondeur max 5, max 100 pages, même domaine uniquement). Chaque page est convertie en Markdown via `HtmlCleaner` (déjà existant), puis envoyée à un LLM gratuit via OpenRouter pour classification binaire : "cette page contient-elle un atelier/stage avec une date ? oui/non". Les URLs "oui" sont automatiquement créées comme nouvelles entrées `ScrapedUrl`, que le pipeline de scraping existant (`ScrapingJob`) prend ensuite en charge. Un mécanisme de hash par page détecte les changements : si la page racine a changé depuis le dernier crawl, tout le site est re-crawlé.

### Scope

**In Scope:**
- Nouveau model `SiteCrawl` (un crawl = une `ScrapedUrl` racine, tracking du dernier crawl)
- Nouveau model `CrawledPage` (pages découvertes, hash contenu, verdict LLM oui/non)
- Service `SiteCrawler` (lib/) : crawl récursif même domaine, profondeur max 5, limite 100 pages, respect robots.txt
- Service `OpenRouterClassifier` (lib/) : appel API OpenRouter, classification binaire markdown → oui/non
- Job `SiteCrawlJob` : exécution asynchrone du crawl complet avec retry 3x exponentiel
- Job `SiteCrawlDispatchJob` : recurring quotidien, vérifie les sites avec `auto_recrawl=true`, relance si page racine changée
- Admin UI :
  - Bouton "Crawler le site" sur `/admin/scraped_urls/:id/show`
  - Page `/admin/site_crawls/:id` : détail des pages trouvées, verdict LLM, statut
  - Page `/admin/site_crawls` : liste paginée des crawls
  - Override modèle LLM au lancement du scan (dropdown dans form)
  - Admin settings : champ `openrouter_default_model` ajouté à `Setting`
- Extension `Setting` model : colonne `openrouter_default_model`
- Extension `ScrapedUrl` : colonnes `auto_recrawl` (boolean), `source_site_crawl_id` (FK nullable pour pages auto-créées)
- Création automatique de `ScrapedUrl` pour pages classées "oui"
- Utilisation de `HtmlCleaner` + `Scrapers::HtmlScraper` / `Scrapers::PlaywrightScraper` existants
- Ajout gem `webmock` dans group `:test`

**Out of Scope:**
- Extraction de données structurées par LLM (oui/non uniquement)
- Pagination JavaScript dynamique (réutilise `use_browser` flag existant)
- Scoring de confiance du LLM
- Crawling multi-domaine
- Détection fine "au moins une page du site a changé" (MVP : seulement page racine)
- Modification du pipeline de scraping existant (`ScrapingEngine`, `ScrapingJob`)
- ~~Attribution automatique du `Professor`~~ → **IN SCOPE** : les ScrapedUrl auto-créées héritent des professors de l'URL racine via `ProfessorScrapedUrl`

## Context for Development

### Codebase Patterns

**Architecture scraping existante :**
- `Scrapers::HtmlScraper.fetch(url)` → `{ html:, status:, content_type: }` ou `{ error: }`, respecte robots.txt
- `Scrapers::PlaywrightScraper.fetch(url)` → même interface, pour sites JS
- `ScrapingEngine.process(scraped_url)` orchestre : fetch → hash SHA256 → diff → save
- `HtmlCleaner.clean_and_convert(html)` → `{ markdown:, data_attributes:, ... }`
- Logger global `SCRAPING_LOGGER` (JSON sur `log/scraping.log`)

**Pattern jobs :**
```ruby
class ScrapingJob < ApplicationJob
  queue_as :scraping
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
end
```

**Pattern Setting singleton :**
```ruby
class Setting < ApplicationRecord
  def self.instance
    first_or_create!
  end
end
```

**Pattern admin actions custom :**
```ruby
resources :scraped_urls do
  member do
    post :crawl_site
  end
end
```

**Pattern recurring :**
```yaml
production:
  site_crawl_dispatch:
    class: SiteCrawlDispatchJob
    schedule: every day at 4am
    queue: scraping
```

**Conventions CLAUDE.md :** Pagy, `Time.current`, `increment_counter`, UTC, retry 3x exponentiel.

### Files to Reference

| File | Purpose |
| ---- | ------- |
| `app/models/scraped_url.rb` | Model racine, ajouter associations `has_many :site_crawls` + `has_many :auto_created_scraped_urls` |
| `lib/scrapers/html_scraper.rb` | Référence interface `fetch(url)` + robots.txt |
| `lib/scrapers/playwright_scraper.rb` | Fallback JS si `use_browser=true` |
| `lib/scraping_engine.rb` | Pattern orchestration (hash, SHA256) |
| `lib/html_cleaner.rb` | Conversion HTML → Markdown réutilisée |
| `app/jobs/scraping_job.rb` | Référence pattern job (retry, queue) |
| `app/jobs/scraping_dispatch_job.rb` | Référence pattern dispatch recurring |
| `app/controllers/admin/scraped_urls_controller.rb` | Ajouter action `crawl_site` |
| `app/views/admin/scraped_urls/show.html.erb` | Ajouter bouton "Crawler le site" |
| `app/views/admin/scraped_urls/preview.html.erb` | Référence pattern `button_to` |
| `app/models/setting.rb` | Extension colonne OpenRouter |
| `app/controllers/admin/settings_controller.rb` | Ajout params `openrouter_default_model` |
| `app/views/admin/settings/edit.html.erb` | Ajout dropdown modèle LLM |
| `config/routes.rb` | Namespace admin, nouveau `resources :site_crawls` |
| `config/recurring.yml` | Ajout job `site_crawl_dispatch` |
| `.env.example` | Ajout `OPENROUTER_API_KEY` |
| `Gemfile` | Ajout `webmock` group `:test` |

### Technical Decisions

1. **Stockage crawl : tables séparées** — `SiteCrawl` (un crawl = une exécution) + `CrawledPage` (N pages par crawl). Historique conservé.
2. **Clé API en ENV, modèle en DB** — `OPENROUTER_API_KEY` en ENV, `openrouter_default_model` en colonne `Setting`.
3. **Crawler maison** — BFS simple avec Nokogiri + `URI.join`, pas de gem externe.
4. **Robots.txt via HtmlScraper** — réutilise la gem `robots` déjà intégrée.
5. **Hash SHA256** — cohérent avec `ScrapingEngine`.
6. **Détection changement MVP** — re-crawl si hash de la page racine a changé.
7. **Rate limiting OpenRouter** — `sleep 3` entre appels (modèles gratuits ~20 req/min).
8. **Gestion erreurs** — erreur fetch → marquer page + continuer. Erreur OpenRouter → retry 2x interne puis `llm_verdict=nil`.
9. **Tests** — WebMock pour mocker OpenRouter et HTTP crawler.
10. **Source_site_crawl_id** — tracer l'origine des `ScrapedUrl` auto-créées.

## Implementation Plan

### Tasks

**Phase 1 : Infrastructure base de données**

- [ ] **Task 1 : Migration `create_site_crawls`**
  - File : `db/migrate/YYYYMMDDHHMMSS_create_site_crawls.rb`
  - Action : Créer table `site_crawls`
  - Colonnes :
    - `id` (bigint, pk)
    - `scraped_url_id` (bigint, FK → scraped_urls, index, null: false)
    - `started_at` (datetime, null: true)
    - `finished_at` (datetime, null: true)
    - `statut` (string, default: "pending", null: false) — valeurs: pending/running/completed/failed
    - `pages_found` (integer, default: 0)
    - `pages_classified_yes` (integer, default: 0)
    - `pages_classified_no` (integer, default: 0)
    - `llm_model_used` (string, null: true)
    - `error_message` (text, null: true)
    - `created_at`, `updated_at`
  - Commande : `bin/rails generate migration CreateSiteCrawls`

- [ ] **Task 2 : Migration `create_crawled_pages`**
  - File : `db/migrate/YYYYMMDDHHMMSS_create_crawled_pages.rb`
  - Action : Créer table `crawled_pages`
  - Colonnes :
    - `id` (bigint, pk)
    - `site_crawl_id` (bigint, FK → site_crawls, index, null: false)
    - `url` (string, null: false)
    - `depth` (integer, null: false, default: 0)
    - `content_hash` (string, null: true) — SHA256 du HTML brut
    - `llm_verdict` (boolean, null: true) — true=oui, false=non, nil=erreur/pas classé
    - `http_status` (integer, null: true)
    - `error_message` (text, null: true)
    - `created_at`, `updated_at`
  - Index unique : `add_index :crawled_pages, [:site_crawl_id, :url], unique: true`

- [ ] **Task 3 : Migration `add_openrouter_config_to_settings`**
  - File : `db/migrate/YYYYMMDDHHMMSS_add_openrouter_config_to_settings.rb`
  - Action : `add_column :settings, :openrouter_default_model, :string, default: "meta-llama/llama-3.3-70b-instruct:free"`

- [ ] **Task 4 : Migration `add_auto_recrawl_to_scraped_urls`**
  - File : `db/migrate/YYYYMMDDHHMMSS_add_auto_recrawl_to_scraped_urls.rb`
  - Action : `add_column :scraped_urls, :auto_recrawl, :boolean, default: false, null: false`

- [ ] **Task 5 : Migration `add_source_site_crawl_to_scraped_urls`**
  - File : `db/migrate/YYYYMMDDHHMMSS_add_source_site_crawl_to_scraped_urls.rb`
  - Action : `add_reference :scraped_urls, :source_site_crawl, foreign_key: { to_table: :site_crawls }, null: true, index: true`
  - Note : nullable car les ScrapedUrl existantes n'ont pas de source

- [ ] **Task 6 : Exécuter les migrations**
  - Commande : `bin/rails db:migrate`
  - Vérification : `bin/rails runner "puts SiteCrawl.column_names.inspect"` et idem pour `CrawledPage`

**Phase 2 : Models**

- [ ] **Task 7 : Model `SiteCrawl`**
  - File : `app/models/site_crawl.rb` (nouveau)
  - Contenu :
    ```ruby
    class SiteCrawl < ApplicationRecord
      belongs_to :scraped_url
      has_many :crawled_pages, dependent: :destroy
      has_many :auto_created_scraped_urls, class_name: "ScrapedUrl", foreign_key: "source_site_crawl_id", dependent: :nullify

      STATUTS = %w[pending running completed failed].freeze
      validates :statut, inclusion: { in: STATUTS }

      scope :recent, -> { order(created_at: :desc) }
      scope :completed, -> { where(statut: "completed") }

      def root_page
        crawled_pages.where(depth: 0).first
      end
    end
    ```

- [ ] **Task 8 : Model `CrawledPage`**
  - File : `app/models/crawled_page.rb` (nouveau)
  - Contenu :
    ```ruby
    class CrawledPage < ApplicationRecord
      belongs_to :site_crawl

      validates :url, presence: true
      validates :url, uniqueness: { scope: :site_crawl_id }
      validates :depth, numericality: { greater_than_or_equal_to: 0 }

      scope :classified_yes, -> { where(llm_verdict: true) }
      scope :classified_no, -> { where(llm_verdict: false) }
    end
    ```

- [ ] **Task 9 : Étendre `ScrapedUrl`**
  - File : `app/models/scraped_url.rb`
  - Action : Ajouter associations
    ```ruby
    has_many :site_crawls, dependent: :destroy
    belongs_to :source_site_crawl, class_name: "SiteCrawl", optional: true
    ```

- [ ] **Task 10 : Étendre `Setting`** (aucun changement de code nécessaire car colonne ajoutée et AR attributs auto — juste vérification)
  - File : `app/models/setting.rb`
  - Action : Pas de changement (colonne auto-détectée). Optionnel : ajouter validation `validates :openrouter_default_model, presence: true`

**Phase 3 : Services (lib/)**

- [ ] **Task 11 : Initializer OpenRouter**
  - File : `config/initializers/open_router.rb` (nouveau)
  - Contenu :
    ```ruby
    OPEN_ROUTER_CONFIG = {
      api_key: ENV.fetch("OPENROUTER_API_KEY", nil),
      base_url: "https://openrouter.ai/api/v1",
      timeout: ENV.fetch("OPENROUTER_TIMEOUT", "30").to_i,
      rate_limit_sleep: ENV.fetch("OPENROUTER_RATE_LIMIT_SLEEP", "3").to_i
    }.freeze
    ```

- [ ] **Task 12 : Service `OpenRouterClassifier`**
  - File : `lib/open_router_classifier.rb` (nouveau)
  - Interface : `OpenRouterClassifier.classify(markdown:, model:)` → `{ verdict: true|false|nil, error: nil|string }`
  - Implémentation :
    ```ruby
    class OpenRouterClassifier
      PROMPT = <<~PROMPT
        Tu es un classifieur. Réponds UNIQUEMENT par "oui" ou "non" (un seul mot, en minuscules).

        Question : Le contenu markdown suivant contient-il la description d'au moins un atelier, stage, ou cours de danse avec une date (jour, mois, ou date complète) ?

        Contenu :
        %{markdown}
      PROMPT

      def self.classify(markdown:, model:)
        return { verdict: nil, error: "API key missing" } if OPEN_ROUTER_CONFIG[:api_key].blank?
        return { verdict: nil, error: "Empty markdown" } if markdown.blank?

        # Truncate markdown to ~10k chars for token safety
        truncated = markdown.first(10_000)
        prompt = format(PROMPT, markdown: truncated)

        response = HTTParty.post(
          "#{OPEN_ROUTER_CONFIG[:base_url]}/chat/completions",
          headers: {
            "Authorization" => "Bearer #{OPEN_ROUTER_CONFIG[:api_key]}",
            "Content-Type" => "application/json",
            "HTTP-Referer" => "https://stopand.dance",
            "X-Title" => "Stop & Dance"
          },
          body: {
            model: model,
            messages: [{ role: "user", content: prompt }],
            temperature: 0,
            max_tokens: 10
          }.to_json,
          timeout: OPEN_ROUTER_CONFIG[:timeout]
        )

        if response.success?
          raw = response.dig("choices", 0, "message", "content").to_s.strip.downcase
          verdict = raw.start_with?("oui") ? true : (raw.start_with?("non") ? false : nil)
          sleep OPEN_ROUTER_CONFIG[:rate_limit_sleep]
          { verdict: verdict, error: verdict.nil? ? "Unparseable response: #{raw}" : nil }
        else
          { verdict: nil, error: "HTTP #{response.code}: #{response.body}" }
        end
      rescue => e
        { verdict: nil, error: e.message }
      end
    end
    ```

- [ ] **Task 13 : Service `SiteCrawler`**
  - File : `lib/site_crawler.rb` (nouveau)
  - Interface : `SiteCrawler.new(scraped_url, llm_model: nil).crawl!` → persiste `SiteCrawl` + `CrawledPage`s
  - Constantes : `MAX_DEPTH = 5`, `MAX_PAGES = 100`
  - Algorithme :
    1. Créer `SiteCrawl` avec `statut: "running"`, `started_at: Time.current`
    2. BFS : queue `[{ url: root_url, depth: 0 }]`, `visited = Set.new`, `pages_count = 0`
    3. Tant que queue non vide ET `pages_count < MAX_PAGES` :
       - Pop, skip si déjà visité, skip si domaine différent, skip si depth > MAX_DEPTH
       - Fetch via `Scrapers::HtmlScraper.fetch` (ou `PlaywrightScraper` si `scraped_url.use_browser`)
       - Calculer `content_hash = Digest::SHA256.hexdigest(html)`
       - Convertir HTML → Markdown via `HtmlCleaner.clean_and_convert(html)`
       - Appeler `OpenRouterClassifier.classify(markdown:, model: effective_model)`
       - Créer `CrawledPage` avec toutes les infos
       - Extraire liens : `Nokogiri::HTML(html).css('a[href]').map { |a| a['href'] }`
       - Normaliser : `URI.join(root_url, href).to_s` + filtrer même domaine + dédupliquer + ajouter à queue avec `depth + 1`
    4. Finaliser `SiteCrawl` : `statut: "completed"`, `finished_at: Time.current`, `pages_found`, `pages_classified_yes`, `pages_classified_no`, `llm_model_used`
    5. Pour chaque `CrawledPage.classified_yes` : si `ScrapedUrl.find_by(url: page.url).nil?`, créer `ScrapedUrl.create!(url: page.url, nom: "Auto-crawl: #{URI.parse(page.url).host}", use_browser: scraped_url.use_browser, statut_scraping: "actif", source_site_crawl_id: site_crawl.id)`
  - Héritage professors : après création de chaque `ScrapedUrl` auto, copier les associations `ProfessorScrapedUrl` de l'URL racine :
    ```ruby
    scraped_url.professors.each do |prof|
      ProfessorScrapedUrl.find_or_create_by!(professor: prof, scraped_url: new_scraped_url)
    end
    ```
  - Logger : `SCRAPING_LOGGER.info({ event: "site_crawl_started|page_crawled|site_crawl_completed", ... }.to_json)`
  - Gestion erreur : raise si la racine échoue fetch. Sinon continuer malgré les erreurs par page.

**Phase 4 : Jobs**

- [ ] **Task 14 : Job `SiteCrawlJob`**
  - File : `app/jobs/site_crawl_job.rb` (nouveau)
  - Contenu :
    ```ruby
    class SiteCrawlJob < ApplicationJob
      queue_as :scraping
      retry_on StandardError, wait: :exponentially_longer, attempts: 3

      def perform(scraped_url_id, llm_model: nil)
        scraped_url = ScrapedUrl.find(scraped_url_id)
        SiteCrawler.new(scraped_url, llm_model: llm_model).crawl!
      rescue => e
        SCRAPING_LOGGER.error({ event: "site_crawl_job_failed", scraped_url_id: scraped_url_id, error: e.message }.to_json)
        raise
      end
    end
    ```

- [ ] **Task 15 : Job `SiteCrawlDispatchJob` (recurring)**
  - File : `app/jobs/site_crawl_dispatch_job.rb` (nouveau)
  - Contenu :
    ```ruby
    class SiteCrawlDispatchJob < ApplicationJob
      queue_as :scraping

      def perform
        ScrapedUrl.where(auto_recrawl: true).find_each do |scraped_url|
          last_crawl = scraped_url.site_crawls.completed.recent.first
          next if last_crawl.nil? # Jamais crawlé : on attend lancement manuel

          # Fetch page racine pour comparer hash
          scraper = scraped_url.use_browser ? Scrapers::PlaywrightScraper : Scrapers::HtmlScraper
          result = scraper.fetch(scraped_url.url)
          next if result[:error]

          current_hash = Digest::SHA256.hexdigest(result[:html])
          root_page = last_crawl.root_page
          next if root_page && root_page.content_hash == current_hash

          SCRAPING_LOGGER.info({ event: "site_crawl_auto_relaunch", scraped_url_id: scraped_url.id }.to_json)
          SiteCrawlJob.perform_later(scraped_url.id)
        end
      end
    end
    ```

**Phase 5 : Admin UI**

- [ ] **Task 16 : Route `crawl_site`**
  - File : `config/routes.rb`
  - Action : Dans `resources :scraped_urls`, bloc `member do`, ajouter `post :crawl_site`
  - Ajouter aussi : `resources :site_crawls, only: [:index, :show]` dans namespace admin

- [ ] **Task 17 : Controller action `crawl_site`**
  - File : `app/controllers/admin/scraped_urls_controller.rb`
  - Action : Ajouter méthode
    ```ruby
    def crawl_site
      llm_model = params[:llm_model].presence || Setting.instance.openrouter_default_model
      SiteCrawlJob.perform_later(@scraped_url.id, llm_model: llm_model)
      redirect_to admin_scraped_url_path(@scraped_url), notice: "Crawl du site lancé (modèle: #{llm_model})"
    end
    ```
  - Ajouter `:crawl_site` au `before_action :find_scraped_url` si présent

- [ ] **Task 18 : Bouton dans `show.html.erb`**
  - File : `app/views/admin/scraped_urls/show.html.erb`
  - Action : Ajouter button_to + select modèle LLM
    ```erb
    <%= form_with url: crawl_site_admin_scraped_url_path(@scraped_url), method: :post, local: true, class: "inline-flex gap-2" do |f| %>
      <%= f.select :llm_model,
                   options_for_select([
                     ["Défaut: #{Setting.instance.openrouter_default_model}", ""],
                     ["Llama 3.3 70B (free)", "meta-llama/llama-3.3-70b-instruct:free"],
                     ["Gemini 2.0 Flash (free)", "google/gemini-2.0-flash-exp:free"],
                     ["DeepSeek Chat (free)", "deepseek/deepseek-chat:free"]
                   ]),
                   {}, class: "border rounded px-2 py-1" %>
      <%= f.submit "Crawler le site", class: "bg-purple-600 text-white px-4 py-2 rounded", data: { confirm: "Lancer le crawl complet du site ?" } %>
    <% end %>
    ```
  - Ajouter aussi checkbox `auto_recrawl` dans `_form.html.erb` de `scraped_urls`

- [ ] **Task 19 : Controller `Admin::SiteCrawlsController`**
  - File : `app/controllers/admin/site_crawls_controller.rb` (nouveau)
  - Actions :
    ```ruby
    class Admin::SiteCrawlsController < Admin::ApplicationController
      def index
        @pagy, @site_crawls = pagy(SiteCrawl.includes(:scraped_url).recent, limit: 20)
      end

      def show
        @site_crawl = SiteCrawl.find(params[:id])
        @pagy, @crawled_pages = pagy(@site_crawl.crawled_pages.order(:depth, :url), limit: 50)
      end
    end
    ```

- [ ] **Task 20 : Vue `site_crawls/index.html.erb`**
  - File : `app/views/admin/site_crawls/index.html.erb` (nouveau)
  - Contenu : table avec colonnes `scraped_url.nom | statut | started_at | pages_found | pages_classified_yes | llm_model_used | actions (Voir)` + pagination Pagy

- [ ] **Task 21 : Vue `site_crawls/show.html.erb`**
  - File : `app/views/admin/site_crawls/show.html.erb` (nouveau)
  - Contenu : résumé `SiteCrawl` + table des `CrawledPage` : `url | depth | llm_verdict (✅/❌/⚠️) | http_status | error_message` + pagination

- [ ] **Task 22 : Admin Settings — champ modèle**
  - File : `app/controllers/admin/settings_controller.rb`
  - Action : Ajouter `:openrouter_default_model` aux strong params
  - File : `app/views/admin/settings/edit.html.erb`
  - Action : Ajouter champ
    ```erb
    <div>
      <%= f.label :openrouter_default_model, "Modèle OpenRouter par défaut" %>
      <%= f.select :openrouter_default_model, options_for_select([
        ["Llama 3.3 70B (free)", "meta-llama/llama-3.3-70b-instruct:free"],
        ["Gemini 2.0 Flash (free)", "google/gemini-2.0-flash-exp:free"],
        ["DeepSeek Chat (free)", "deepseek/deepseek-chat:free"]
      ], @setting.openrouter_default_model), {}, class: "border rounded px-2 py-1" %>
    </div>
    ```

**Phase 6 : Recurring + Env**

- [ ] **Task 23 : Ajouter job recurring**
  - File : `config/recurring.yml`
  - Action : Ajouter sous `production:`
    ```yaml
    site_crawl_dispatch:
      class: SiteCrawlDispatchJob
      schedule: every day at 4am
      queue: scraping
    ```

- [ ] **Task 24 : Ajouter variables ENV**
  - File : `.env.example`
  - Action : Ajouter
    ```bash
    OPENROUTER_API_KEY=sk-or-v1-xxx
    OPENROUTER_TIMEOUT=30
    OPENROUTER_RATE_LIMIT_SLEEP=3
    ```
  - File : `.env` (local, pas committé)
  - Action : Duy obtient une clé sur https://openrouter.ai et l'ajoute

**Phase 7 : Tests**

- [ ] **Task 25 : Ajouter WebMock**
  - File : `Gemfile`
  - Action : Ajouter dans group `:test`
    ```ruby
    group :test do
      gem "webmock"
    end
    ```
  - File : `test/test_helper.rb`
  - Action : Ajouter `require "webmock/minitest"` et `WebMock.disable_net_connect!(allow_localhost: true)`
  - Commande : `bundle install`

- [ ] **Task 26 : Tests model `SiteCrawl`**
  - File : `test/models/site_crawl_test.rb` (nouveau)
  - Tests :
    - validité avec scraped_url + statut valide
    - invalidité sans scraped_url ou statut hors liste
    - scope `.recent` ordonne par created_at desc
    - scope `.completed` filtre
    - `root_page` retourne page depth=0

- [ ] **Task 27 : Tests model `CrawledPage`**
  - File : `test/models/crawled_page_test.rb` (nouveau)
  - Tests :
    - validité avec url + site_crawl + depth
    - unicité (url, site_crawl_id)
    - scope `classified_yes/no`

- [ ] **Task 28 : Tests service `OpenRouterClassifier`**
  - File : `test/lib/open_router_classifier_test.rb` (nouveau)
  - Tests WebMock :
    - réponse "oui" → `verdict: true`
    - réponse "non" → `verdict: false`
    - réponse malformée → `verdict: nil, error: ...`
    - HTTP 429 → `verdict: nil, error: "HTTP 429..."`
    - timeout → `verdict: nil, error: ...`
    - API key absente → `verdict: nil, error: "API key missing"`

- [ ] **Task 29 : Tests service `SiteCrawler`**
  - File : `test/lib/site_crawler_test.rb` (nouveau)
  - Tests WebMock :
    - crawl simple 1 page → 1 `CrawledPage` + classification
    - crawl 3 pages liées → 3 `CrawledPage` avec depths correctes
    - limite `MAX_PAGES` respectée
    - limite `MAX_DEPTH` respectée
    - skip liens externes (autre domaine)
    - pages "oui" créent des `ScrapedUrl`
    - ne recrée pas `ScrapedUrl` si URL existe déjà

- [ ] **Task 30 : Tests job `SiteCrawlJob`**
  - File : `test/jobs/site_crawl_job_test.rb` (nouveau)
  - Tests :
    - enqueue avec bon queue
    - perform appelle `SiteCrawler` (mock)
    - retry sur StandardError

- [ ] **Task 31 : Tests job `SiteCrawlDispatchJob`**
  - File : `test/jobs/site_crawl_dispatch_job_test.rb` (nouveau)
  - Tests :
    - n'enqueue rien si aucune ScrapedUrl avec `auto_recrawl=true`
    - enqueue si hash racine a changé
    - n'enqueue pas si hash identique
    - skip si aucun crawl complété antérieur

- [ ] **Task 32 : Tests controller `Admin::SiteCrawlsController`**
  - File : `test/controllers/admin/site_crawls_controller_test.rb` (nouveau)
  - Tests :
    - index avec HTTP Basic Auth → 200
    - index sans auth → 401
    - show avec id valide → 200

- [ ] **Task 33 : Tests controller action `crawl_site`**
  - File : `test/controllers/admin/scraped_urls_controller_test.rb`
  - Tests :
    - POST crawl_site enqueue `SiteCrawlJob`
    - Redirect avec notice

**Phase 8 : Validation**

- [ ] **Task 34 : Lint + tests**
  - Commandes :
    ```bash
    bin/rubocop
    bin/rails test
    bin/brakeman --no-progress
    ```
  - Corriger toute erreur.

- [ ] **Task 35 : Test manuel end-to-end (dev)**
  - Obtenir clé OpenRouter, ajouter dans `.env`
  - Redémarrer serveur
  - Sur `/admin/scraped_urls/:id` cliquer "Crawler le site" sur un site connu (ex: site d'un prof)
  - Vérifier `/admin/site_crawls/:id` : pages trouvées + classification
  - Vérifier que des `ScrapedUrl` ont été créées pour les pages "oui"
  - Vérifier logs `tail -f log/scraping.log`

### Acceptance Criteria

- [ ] **AC 1** : Given une `ScrapedUrl` racine existante, when je clique "Crawler le site" depuis `/admin/scraped_urls/:id`, then un `SiteCrawlJob` est enqueué et je vois un message "Crawl du site lancé".

- [ ] **AC 2** : Given un `SiteCrawlJob` en cours, when il s'exécute, then un `SiteCrawl` est créé avec `statut=running`, puis passe à `completed` à la fin avec `pages_found`, `pages_classified_yes` et `pages_classified_no` remplis.

- [ ] **AC 3** : Given un site avec 3 pages (racine + 2 liées même domaine), when le crawl s'exécute, then 3 `CrawledPage` sont créées avec `depth` = 0, 1, 1 et `content_hash` non null.

- [ ] **AC 4** : Given un site avec des liens externes, when le crawl s'exécute, then aucune page hors domaine n'est crawlée.

- [ ] **AC 5** : Given un site avec plus de 100 pages, when le crawl s'exécute, then exactement 100 `CrawledPage` max sont créées (limite respectée).

- [ ] **AC 6** : Given un site profond (niveaux 0-6), when le crawl s'exécute, then aucune page avec `depth > 5` n'est crawlée.

- [ ] **AC 7** : Given une page classée "oui" par le LLM et dont l'URL n'existe pas en base, when le crawl finalise, then une nouvelle `ScrapedUrl` est créée avec `nom="Auto-crawl: {hostname}"`, `statut_scraping="actif"`, et `source_site_crawl_id` pointant vers le crawl.

- [ ] **AC 8** : Given une page classée "oui" dont l'URL existe déjà dans `ScrapedUrl`, when le crawl finalise, then aucune nouvelle `ScrapedUrl` n'est créée (pas de doublon).

- [ ] **AC 8b** : Given une URL racine avec 2 professors associés et une page classée "oui", when la `ScrapedUrl` auto-créée est finalisée, then elle a les mêmes 2 professors associés via `ProfessorScrapedUrl`.

- [ ] **AC 9** : Given un `ScrapedUrl` avec `auto_recrawl=true` et un dernier `SiteCrawl` complété, when `SiteCrawlDispatchJob` s'exécute et que le hash de la page racine a changé, then un nouveau `SiteCrawlJob` est enqueué.

- [ ] **AC 10** : Given un `ScrapedUrl` avec `auto_recrawl=true` et un hash racine inchangé, when `SiteCrawlDispatchJob` s'exécute, then aucun job n'est enqueué.

- [ ] **AC 11** : Given OpenRouter répond 429 (rate limit), when `OpenRouterClassifier.classify` est appelé, then il retourne `{ verdict: nil, error: "HTTP 429..." }` sans crasher le crawl.

- [ ] **AC 12** : Given `OPENROUTER_API_KEY` absente, when `OpenRouterClassifier.classify` est appelé, then il retourne `{ verdict: nil, error: "API key missing" }` immédiatement.

- [ ] **AC 13** : Given l'admin visite `/admin/site_crawls`, when la page charge, then il voit la liste paginée des crawls avec statut et stats, avec HTTP Basic Auth requis.

- [ ] **AC 14** : Given l'admin visite `/admin/site_crawls/:id`, when la page charge, then il voit la table des `CrawledPage` triée par depth et url, avec verdict LLM affiché (✅ / ❌ / ⚠️).

- [ ] **AC 15** : Given l'admin modifie `openrouter_default_model` dans `/admin/settings/edit` et enregistre, when il lance ensuite un crawl sans override, then le modèle utilisé est celui enregistré dans Setting.

- [ ] **AC 16** : Given l'admin lance un crawl avec override LLM dans le form, when le crawl s'exécute, then `SiteCrawl.llm_model_used` contient le modèle override et non celui de Setting.

- [ ] **AC 17** : Given une page dont le fetch HTTP échoue (404, 500, timeout), when le crawl continue, then une `CrawledPage` est créée avec `http_status` correct, `error_message` rempli, `llm_verdict=nil`, et le crawl continue les autres pages.

- [ ] **AC 18** : Given `bin/rails test`, when tous les tests tournent, then tous passent (y compris les nouveaux tests models/services/jobs/controllers).

- [ ] **AC 19** : Given `bin/rubocop` et `bin/brakeman`, when ils tournent, then zéro erreur/warning.

- [ ] **AC 20** : Given un crawl complet de 10 pages avec modèle gratuit OpenRouter, when on mesure le temps total, then < 2 minutes (grâce au `sleep 3` de rate limit : ~30s min + fetch + overhead).

## Additional Context

### Dependencies

**Externes :**
- Compte OpenRouter (gratuit) : https://openrouter.ai
- Clé API OpenRouter (variable `OPENROUTER_API_KEY`)
- Modèles gratuits disponibles sur OpenRouter (Llama 3.3, Gemini Flash, DeepSeek)

**Gems à ajouter :**
- `webmock` (group `:test`)

**Gems déjà présentes (réutilisées) :**
- `httparty` — appels HTTP vers OpenRouter
- `nokogiri` — parsing HTML et extraction des liens
- `reverse_markdown` — déjà utilisé par `HtmlCleaner`
- `robots` — déjà utilisé par `HtmlScraper`

**Tâches préalables :** Aucune (feature autonome, se greffe sur scraping existant).

### Testing Strategy

**Unit tests (models) :**
- `SiteCrawl`, `CrawledPage` : validations, associations, scopes

**Service tests (lib/) :**
- `OpenRouterClassifier` : tous les chemins d'erreur via WebMock
- `SiteCrawler` : BFS complet avec HTML stubbé, limites respectées, classification, création auto ScrapedUrl

**Job tests :**
- `SiteCrawlJob` : enqueue/perform, retry
- `SiteCrawlDispatchJob` : logique de détection de changement

**Controller tests :**
- `Admin::SiteCrawlsController` : auth, index, show
- `Admin::ScrapedUrlsController#crawl_site` : enqueue job, redirect

**Test manuel end-to-end (Task 35) :**
- Obligatoire avant merge
- Sur un site réel (ex: un site de prof existant)
- Vérifier création auto des ScrapedUrl
- Vérifier logs

### Notes

**Risques identifiés :**

1. **Rate limiting OpenRouter trop agressif** → Risque : crawl interrompu par 429. Mitigation : `sleep 3` entre appels (configurable via ENV). Si problème, passer à modèle payant ou réduire `MAX_PAGES`.

2. **Sites avec URLs dynamiques (query params, fragments)** → Risque : explosion combinatoire. Mitigation : normaliser en retirant fragments (`#foo`) et query params non essentiels. **À affiner pendant implémentation**.

3. **Boucles infinies via redirects** → Mitigation : `HtmlScraper` utilise déjà `follow_redirects: true` et `Set.new` pour les URLs visitées évite les boucles.

4. **Fetch Playwright lent (5s/page)** → Risque : 100 pages × 5s = 8 minutes. Mitigation : MVP utilise `use_browser` du `ScrapedUrl` racine pour toutes les pages. V2 : détection intelligente par page.

5. **Détection changement MVP (hash racine uniquement)** → Limitation acceptée : si un prof ajoute une nouvelle page atelier sans toucher l'accueil, on ne la détecte pas avant le prochain crawl manuel. **V2** : checker N pages aléatoirement.

**Limitations connues :**
- Pas de respect des rel="nofollow"
- Pas de cache LLM (chaque crawl re-classifie tout)
- Pas de retry intelligent sur 429 (juste skip + log)
- `Professor` hérité de l'URL racine (si le prof a plusieurs sites, l'admin ajuste manuellement)

**Future considerations (out of scope MVP) :**
- Détection fine des changements (hash par page comparé entre crawls)
- Extraction structurée par LLM (remplacer `ClaudeCliIntegration` progressivement)
- Cache LLM (si même URL/hash → réutiliser verdict)
- Assignation `Professor` intelligente (via lookup du domaine dans les profs existants, au lieu d'hériter de la racine)
- UI pour bulk-validation des pages auto-classées
- Métriques : coût estimé par crawl, taux de faux positifs/négatifs
