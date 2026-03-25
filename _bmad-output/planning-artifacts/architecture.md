---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
inputDocuments:
  - docs/prd.md
  - docs/brief.md
workflowType: 'architecture'
project_name: '3graces-v2'
user_name: 'Duy'
date: '2026-03-25'
lastStep: 8
status: 'revised'
completedAt: '2026-03-25'
revisedAt: '2026-03-25'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Project Context Analysis

### Requirements Overview

**Functional Requirements:**

Le projet compte 41 exigences fonctionnelles organisées en 7 catégories :

1. **Découverte et Consultation d'Événements (FR1-FR11)** : Agenda chronologique, filtres (date, type, format, gratuit), mode clair/sombre, masquage automatique des événements passés
2. **Engagement Utilisateur (FR12-FR13)** : Newsletter email, profils publics professeurs
3. **Acquisition et Mise à Jour Automatisée du Contenu (FR14-FR20)** : Scraping automatisé (cron 24h), détection changements HTML diff, génération/mise à jour fiches par LLM, journal des changements, persistence PostgreSQL
4. **Administration et Monitoring (FR21-FR25)** : Logs scraping/parsing/erreurs, ajout manuel URLs, notes correctrices par URL, alertes problèmes
5. **Visibilité Professeurs (FR26-FR29)** : Page stats publique (consultations + clics sortants), URL unique sans compte
6. **SEO et Découvrabilité (FR30-FR34)** : Meta tags uniques, Schema.org Event, Open Graph, sitemap XML, URLs sémantiques
7. **Progressive Web App (FR35-FR37)** : Installation mobile, détection nouvelle version, rechargement
8. **Accessibilité (FR38-FR40)** : Navigation clavier complète, lecteurs d'écran, alternatives textuelles

**Non-Functional Requirements:**

Les 19 NFRs couvrent 7 domaines critiques :

- **Performance (NFR-P1 à P5)** : FCP < 1.5s, TTI < 3s, LCP < 2.5s sur 4G, filtres < 500ms
- **Security & Privacy (NFR-S1 à S4)** : Respect robots.txt, RGPD, TLS 1.3, user-agent identifié
- **Reliability & Availability (NFR-R1 à R7)** : 99% autonomie sur 30j, retry exponentiel, alertes < 15min, 99.5% uptime, backups quotidiennes 30j, tolérance erreurs URLs (alerte après 3 cycles échoués)
- **Accessibility (NFR-A1 à A4)** : Lighthouse > 90, WCAG 2.1 AA (contraste 4.5:1), navigation clavier, lecteurs d'écran
- **Integration & Automation (NFR-I1 à I6)** : Claude CLI < 60s/URL, Solid Queue < 5min délai, tolérance 30min indispo CLI, notes correctrices < 100ms, timezone Europe/Paris uniforme, cron 24h
- **Maintainability (NFR-M1 à M3)** : Logs 90j, documentation README, déploiement Docker reproductible
- **Scalability (NFR-SC1 à SC2)** : Support 100 URLs profs sans dégradation, affichage 500 événements LCP < 2.5s

**Scale & Complexity:**

- **Primary domain :** Full-stack web app (Rails 8 MPA) + backend scraping automatisé
- **Complexity level :** Medium (architecture technique sophistiquée, domaine métier standard)
- **Estimated architectural components :** ~8-10 composants principaux (scraping engine, job orchestration, LLM integration, event management, filtering system, newsletter, stats tracking, PWA layer)

### Technical Constraints & Dependencies

**Stack imposée :**
- Rails 8 (MPA + Turbo, pas de framework JS lourd)
- PostgreSQL (timezone Europe/Paris)
- Solid Queue (orchestration cron + jobs, remplace n8n)
- Claude Code CLI headless (abonnement Pro 20$/mois, pas Claude API)
- Tailwind CSS
- Docker sur HP EliteDesk (serveur Linux headless perso)

**Formats scraping MVP :**
- Sites web HTML/HTTP classiques
- Google Calendar
- Helloasso
- Exclus MVP : Instagram, Facebook (authentification requise)

**Contrainte opérationnelle critique :**
- Créateur = nouveau papa, disponibilité très limitée
- Système doit fonctionner 7 jours consécutifs sans intervention (NFR-R1)
- Automatisation maximale absolument requise

**Contrainte technique Claude Code CLI headless :**
- Flag `--dangerously-skip-permissions` requis pour mode headless
- Volume Docker `~/.claude:/root/.claude` pour persister auth
- Validation token avant chaque invocation

### Cross-Cutting Concerns Identified

1. **Timezone Europe/Paris** : Tous les timestamps stockés en UTC, affichés en Europe/Paris via `config.time_zone` (scope France uniquement)
2. **Automatisation et orchestration** : Cron 24h, détection changements, retry exponentiel, alertes email
3. **Fiabilité et monitoring** : Logs 90j, journal changements, alertes erreurs critiques < 15min, backups quotidiennes 30j
4. **Performance web** : Optimisation images (WebP, lazy loading), CSS/JS minifiés, Turbo navigation, cache-busting assets
5. **SEO et découvrabilité** : Meta tags, Schema.org Event, Open Graph, sitemap XML, URLs sémantiques
6. **Accessibilité WCAG 2.1 AA** : Contraste couleurs, navigation clavier, ARIA labels, structure sémantique HTML5, focus visible
7. **Mode clair/sombre** : Toggle utilisateur, préférence sauvegardée, applicable partout (agenda, stats profs, admin logs)
8. **Intégration LLM headless** : Parsing < 60s/URL, tolérance 30min indispo, lecture notes correctrices < 100ms

## Starter Template Evaluation

### Primary Technology Domain

Full-stack web app Rails 8 basé sur les exigences du projet.

### Selected Starter: Rails 8.1.2 (Projet existant)

**Statut :** Le projet Rails 8.1.2 est déjà initialisé dans `~/3graces-v2`. Pas besoin de recréer.

**Architectural Decisions Provided by Rails 8:**

**Language & Runtime :**
- Ruby avec Rails 8.1.2
- Turbo intégré par défaut pour navigation SPA-like

**Styling Solution :**
- Tailwind CSS (à configurer via `tailwindcss-rails` gem)

**Build Tooling :**
- Propshaft (asset pipeline moderne Rails)
- Minification CSS/JS automatique
- Cache-busting via fingerprinting

**Testing Framework :**
- Minitest intégré par défaut

**Code Organization :**
- Structure MVC Rails standard : `app/models/`, `app/controllers/`, `app/views/`
- `app/jobs/` pour Solid Queue
- `lib/` pour scraping engine et intégration Claude Code CLI

**Development Experience :**
- Hot reloading avec `rails server`
- Console Rails pour debugging
- Générateurs Rails pour scaffolding
- Configuration environnement via `.env`

## Core Architectural Decisions

### Decision Priority Analysis

**Critical Decisions (Block Implementation):**
- Data model et relations (Professor, Event, ScrapedUrl, ChangeLog, Newsletter)
- Solid Queue configuration pour orchestration scraping
- Claude Code CLI integration headless avec validation token
- Timezone Europe/Paris uniforme (config Rails + PostgreSQL)
- Caddy reverse proxy pour HTTPS automatique

**Important Decisions (Shape Architecture):**
- Fragment caching Rails pour performance agenda
- Rack::Attack rate limiting basique
- Turbo Frames pour filtres sans rechargement
- Logs structurés avec rotation 90j
- Backups PostgreSQL quotidiens (rétention 30j)

**Deferred Decisions (Post-MVP):**
- Chiffrement AES-256 emails newsletter (attr_encrypted gem)
- Scraping Instagram/Facebook (authentification requise)
- Algolia search + géolocalisation
- Cloudinary pour médias optimisés
- CI/CD automatisé
- Monitoring externe (Sentry, Datadog)

### Data Architecture

**Database:** PostgreSQL (version stable actuelle)
- Timezone: Europe/Paris forcée (`config.time_zone = "Europe/Paris"`)
- Extensions: `pg` gem standard

**Core Models:**

```ruby
# Professor (prof de danse)
- avatar, bio, site_web, email
- stats: consultations_count, clics_sortants_count

# Event (atelier/stage)
- titre, description, tags (array)
- date_debut, date_fin (timestamptz UTC, affichés Europe/Paris)
- duree_minutes (integer, calculé automatiquement via callback)
- lieu, adresse_complete
- prix_normal (decimal), prix_reduit (decimal, nullable)
- type_event: enum { atelier: 0, stage: 1 }
- gratuit (boolean, default: false)
- en_ligne (boolean, default: false)
- en_presentiel (boolean, default: true)
- belongs_to :professor
- belongs_to :scraped_url, optional: true  # nullable — permet création/correction manuelle admin
- has_many :event_sources
- has_many :additional_scraped_urls, through: :event_sources, source: :scraped_url

# ScrapedUrl
- url, notes_correctrices (text)
- derniere_version_html (text, stockage diff)
- statut_scraping, erreurs_consecutives (integer)
- has_many :professor_scraped_urls
- has_many :professors, through: :professor_scraped_urls
- has_many :change_logs

# ChangeLog
- diff_html (text)
- changements_detectes (jsonb)
- timestamp
- belongs_to :scraped_url

# EventSource (traçabilité multi-sources scraping)
- belongs_to :event
- belongs_to :scraped_url
- primary_source (boolean, default: false)
# Permet de tracker toutes les URLs qui mentionnent un même event
# Utile pour déduplication (même event scrapé depuis 2 URLs différentes)

# Newsletter
- email (unique)
- consenti_at (timestamp)
- actif (boolean)
```

**ProfessorScrapedUrl (modèle intermédiaire — extensible) :**
- belongs_to :professor
- belongs_to :scraped_url
# Permet d'ajouter des métadonnées futures (rôle, date association, etc.)

**Validation Strategy:**
- ActiveRecord validations standard (presence, format, uniqueness)
- Timezone validation helper pour garantir Europe/Paris

**Migrations:**
- Rails standard avec `rails generate migration`
- Timestamps automatiques (`created_at`, `updated_at`)

**Caching Strategy:**
- Fragment caching Rails pour liste événements (invalidation post-scraping)
- HTTP caching via `expires_in` pour assets statiques
- In-memory cache Rails suffit pour MVP (pas de Redis nécessaire)

**Rationale:** Stack PostgreSQL imposée par PRD. Relations many-to-many pour ScrapedUrl/Professor permettent ateliers co-animés et collectifs. Timezone uniforme Europe/Paris critique pour scope France (NFR-I5).

### Authentication & Security

**Authentication:**
- Aucune authentification utilisateur (interface read-only par design)
- Admin: Accès terminal SSH uniquement (pas d'interface web admin MVP)
- Stats profs: URL unique publique sans compte (FR29)

**Authorization:**
- Non applicable (pas de rôles, pas d'utilisateurs)

**Security Middleware:**
- Rails standard: CSRF protection, XSS protection, headers sécurisés
- Force HTTPS (TLS 1.3 minimum - NFR-S3)
- Rack::Attack pour rate limiting basique (60 req/min par IP)

**Data Encryption:**
- MVP: Emails newsletter en clair PostgreSQL
- Post-MVP: AES-256 au repos via `attr_encrypted` gem

**API Security:**
- Pas d'API publique pour MVP
- Scraping bot user-agent: `"3graces.community bot - contact@3graces.community"` (NFR-S4)
- Respect robots.txt de chaque site (NFR-S1)

**Rationale:** Interface read-only élimine complexité auth. Focus sécurité sur HTTPS, rate limiting, et identification bot responsable. Chiffrement emails différé post-MVP (optimisation prématurée).

### API & Communication Patterns

**API Design:**
- Pas d'API publique exposée pour MVP (interface web uniquement)
- Communication interne: Jobs Solid Queue → Claude Code CLI via shell exec

**Error Handling:**
- Rails standard (`rescue_from` dans ApplicationController)
- Logs structurés pour scraping/parsing errors (rotation 90j - NFR-M1)
- Alertes email pour erreurs critiques < 15min (NFR-R3)

**Rate Limiting:**
- Rack::Attack configuration basique
- Throttling: 60 requêtes/minute par IP

**Communication Interne:**
- Solid Queue jobs pour orchestration scraping (cron 24h)
- Retry exponentiel: 3 tentatives max (NFR-R2)
- Tolérance 30min indispo Claude CLI (NFR-I3)

**Rationale:** Architecture interne simple (jobs → CLI) sans API complexe. Rate limiting protège ressources serveur. Retry strategy garantit fiabilité scraping (NFR-R1: 99% autonomie 30j).

### Frontend Architecture

**State Management:**
- Aucun framework JS lourd (PRD: MPA + Turbo)
- Stimulus pour interactions légères (toggle mode clair/sombre, filtres)
- Préférence mode clair/sombre: `localStorage`

**Component Architecture:**
- Partials Rails standard
- ViewComponents si composants réutilisables complexes nécessaires
- Turbo Frames pour filtres sans rechargement complet

**Routing:**
- Routes Rails standard
- URLs sémantiques: `/evenements/contact-impro-paris-2026-03-25` (FR34)

**Performance Optimization:**
- Turbo navigation (cache automatique)
- Lazy loading images (`loading="lazy"`)
- WebP + fallback JPEG/PNG
- CSS/JS minifiés via Propshaft
- Fragment caching pour liste événements
- **Infinite Scroll :** Turbo Frames lazy loading par batch de 30 événements
  - Quand l'utilisateur approche du bas de la liste, Turbo Frame charge le batch suivant automatiquement
  - Pas de pagination classique avec numéros de pages
  - Gem `pagy` pour pagination côté serveur (léger, performant)

**Bundle Optimization:**
- Import maps (Rails 8 default)
- Pas de bundler JS complexe (Webpack/Vite)

**Rationale:** MPA + Turbo imposé par PRD (simplicité développement, SEO natif). Stimulus suffit pour interactions légères. Performance targets (FCP < 1.5s, LCP < 2.5s - NFR-P1-P3) atteignables sans framework JS lourd.

### Infrastructure & Deployment

**Hosting:**
- Serveur: HP EliteDesk (Linux headless) avec Docker (imposé PRD)
- Reverse proxy: **Caddy** (HTTPS automatique Let's Encrypt, zéro config manuelle)

**Docker Setup:**
- Container Rails app (Puma)
- Container PostgreSQL
- Container Caddy reverse proxy
- Volume `~/.claude:/root/.claude` pour auth Claude CLI persistante
- Orchestration: `docker-compose`

**CI/CD:**
- Pas de CI/CD automatisé pour MVP (déploiement manuel SSH + docker-compose)
- Git hooks locaux optionnels (tests avant push)

**Environment Configuration:**
- `.env` avec `dotenv-rails` gem
- Variables: `DATABASE_URL`, `CLAUDE_AUTH_TOKEN`, `ALERT_EMAIL`, `RAILS_ENV`, `SECRET_KEY_BASE`

**Monitoring & Logging:**
- Logs: Rails logger standard avec rotation 90j (NFR-M1)
- Monitoring basique: Solid Queue dashboard intégré
- Alertes: Action Mailer pour erreurs critiques < 15min (NFR-R3)
- Pas de monitoring externe (Sentry, Datadog) pour MVP

**Scaling Strategy:**
- MVP: Single server suffit (NFR-SC2: 500 événements, NFR-SC1: 100 URLs profs)
- Horizontal scaling post-MVP si nécessaire (load balancer + multiple containers)

**Backups:**
- PostgreSQL: dump quotidien via cron (rétention 30j - NFR-R5)
- Script: `pg_dump` vers dossier local + rotation automatique
- Commande: `docker exec postgres pg_dump -U postgres 3graces_production > backup_$(date +%Y%m%d).sql`

**Rationale:** Docker garantit reproductibilité déploiement (NFR-M3). Caddy élimine complexité config HTTPS manuelle (critique pour admin seul disponibilité limitée). Backups quotidiens assurent résilience données (NFR-R5). Single server suffit pour scale MVP.

### Decision Impact Analysis

**Implementation Sequence:**
1. Database schema & migrations (Professor, Event, ScrapedUrl, ChangeLog, Newsletter)
2. Solid Queue configuration + cron jobs scraping
3. Scraping engine (fetch HTML, diff detection, storage)
4. Claude Code CLI integration headless (shell exec + token validation)
5. Event management (CRUD admin, affichage public)
6. Filtres et recherche basique (Turbo Frames)
7. Newsletter inscription
8. Stats profs (tracking consultations/clics)
9. SEO (meta tags, Schema.org, sitemap)
10. Docker Compose + Caddy reverse proxy
11. Backups automatisés + monitoring logs

**Cross-Component Dependencies:**
- ScrapedUrl doit exister avant Event (foreign key)
- Claude CLI auth doit être validée avant scraping jobs
- Fragment caching invalide après chaque scraping success
- Timezone Europe/Paris forcée au niveau application (impacte tous timestamps)
- Caddy config dépend de DNS configuré pour 3graces.community

## Implementation Patterns & Consistency Rules

### Pattern Categories Defined

**Critical Conflict Points Identified:** 8 catégories où agents AI pourraient faire des choix différents (naming, structure, formats, communication, processus, error handling, loading states, validation)

### Naming Patterns

**Database Naming (Rails conventions) :**
- Tables : `professors`, `events`, `scraped_urls` (snake_case pluriel)
- Colonnes : `site_web`, `date_debut`, `date_fin`, `prix_normal`, `duree_minutes` (snake_case)
- Foreign keys : `professor_id`, `scraped_url_id` (singulier + `_id`)
- Join table : `professors_scraped_urls` (alphabétique, pluriels)
- Index : `index_events_on_date_debut` (Rails convention)

**API/Route Naming (Rails conventions) :**
- Routes REST : `/evenements`, `/professeurs` (pluriel, français pour URLs publiques)
- Params : `params[:id]`, `params[:event]` (symbol keys)
- Query params : `date_debut`, `gratuit`, `en_ligne` (snake_case cohérent avec DB)

**Code Naming (Ruby/Rails conventions) :**
- Models : `Professor`, `Event`, `ScrapedUrl` (PascalCase singulier)
- Controllers : `EventsController`, `ProfessorsController` (pluriel + Controller suffix)
- Jobs : `ScrapingJob`, `EventUpdateJob` (Job suffix)
- Services : `ScrapingEngine`, `ClaudeCliIntegration` (descriptifs, dans `lib/`)
- Méthodes : `fetch_html`, `detect_changes`, `send_alert_email`, `calculate_duration` (snake_case verbes)
- Variables : `scraped_url`, `change_log`, `professor_ids`, `duree_minutes` (snake_case)

### Structure Patterns

**Project Organization (Rails conventions) :**
- Tests : `test/models/`, `test/jobs/`, `test/integration/` (Minitest standard)
- Services/Libs : `lib/scraping_engine.rb`, `lib/claude_cli.rb`
- Jobs : `app/jobs/scraping_job.rb`
- Helpers : `app/helpers/events_helper.rb`
- Views : `app/views/events/index.html.erb`

**Configuration :**
- Environment : `.env` (root, pas commité)
- Secrets : `config/credentials.yml.enc` (Rails encrypted credentials)
- Initializers : `config/initializers/solid_queue.rb`, `config/initializers/timezone.rb`

### Format Patterns

**Timestamps :**
- **CRITIQUE :** Tous timestamps stockés en UTC, affichés en Europe/Paris (`date_debut`, `date_fin`)
- Format stockage DB : `timestamptz` UTC (Rails convertit automatiquement vers Europe/Paris à l'affichage via `config.time_zone`)
- Format affichage : `"25 mars 2026, 19h30"` (français, 24h, timezone Europe/Paris)
- Format logs : ISO 8601 avec timezone (`2026-03-25T19:30:00+01:00`)
- **Rationale :** Stocker en UTC évite bugs changements heure été/hiver (une heure existe 2x en octobre, une heure n'existe pas en mars)

**JSON (si API future) :**
- Field naming : `snake_case` (cohérent avec DB/Ruby)
- Booleans : `true`/`false`
- Nulls : `null` acceptés
- Dates : ISO 8601 strings avec timezone
- Decimals : strings pour prix (`"45.00"`) pour éviter arrondis JS

**Responses Rails (HTML + Turbo) :**
- Success : Turbo Stream pour updates partiels
- Errors : Flash messages + `422 Unprocessable Entity`
- Redirects : `303 See Other` après POST

### Communication Patterns

**Solid Queue Jobs :**
- Naming : `ScrapingJob`, `EventUpdateJob` (verbe + Job suffix)
- Arguments : Hash avec symbol keys `{scraped_url_id: 123}`
- Priority : `:default` (0), `:low` (-10), `:high` (10)
- Queue names : `:default`, `:scraping`, `:notifications`

**Event Broadcasting (Turbo Streams) :**
- Stream names : `"events"`, `"professor_#{id}"` (snake_case)
- Actions : `:append`, `:update`, `:remove`, `:replace`

**Logging :**
- Format : `[TIMESTAMP] LEVEL -- ComponentName: Message {context}`
- Levels : `debug` (développement), `info` (events normaux), `warn` (anomalies), `error` (critique), `fatal` (crash)
- Context : Hash avec données structurées `{scraped_url_id: 123, duration_ms: 450}`

### Process Patterns

**Error Handling :**
- Jobs : Retry exponentiel 3x (Solid Queue configuré : `retry_on StandardError, wait: :exponentially_longer, attempts: 3`)
- Controllers : `rescue_from` dans `ApplicationController` pour erreurs globales
- Scraping errors : Log + incrément `erreurs_consecutives`, alerte si > 3 cycles
- User errors : Flash messages français (`alert`, `notice`)

**Loading States (Turbo) :**
- Turbo Frame : `<turbo-frame id="events-list" src="/evenements" loading="lazy">`
- Skeleton screens : Partials `_loading.html.erb` avec animation CSS
- Global loading : Turbo progress bar (défaut Rails)

**Validation :**
- Server-side : ActiveRecord validations (priorité absolue)
- Client-side : HTML5 attributes (`required`, `pattern`) pour UX
- Timezone : Input utilisateur parsé en Europe/Paris via `Time.zone.parse` (Rails gère conversion UTC automatiquement)
- Calculs automatiques : `duree_minutes` calculé via callback `before_save` depuis `date_debut`/`date_fin`

### Enforcement Guidelines

**All AI Agents MUST:**

1. **TOUJOURS** stocker timestamps en UTC (défaut Rails), afficher en Europe/Paris via `config.time_zone`
2. **TOUJOURS** suivre conventions naming Rails (snake_case DB/code, PascalCase classes)
3. **TOUJOURS** utiliser retry exponentiel 3x pour jobs Solid Queue
4. **TOUJOURS** logger avec format structuré `{context}` pour traçabilité
5. **TOUJOURS** respecter relations DB (has_many :through professor_scraped_urls, foreign keys)
6. **TOUJOURS** calculer `duree_minutes` automatiquement via callback (pas d'input manuel)
7. **JAMAIS** créer d'authentification utilisateur (interface read-only par design)
8. **JAMAIS** utiliser framework JS lourd (Turbo + Stimulus uniquement)

**Pattern Enforcement:**

- Vérification : Linters Rails (RuboCop avec config Rails)
- Tests : Assertions stockage UTC (`assert event.date_debut.utc?`) + affichage formaté Europe/Paris
- Code review : Checklist patterns dans PR template
- Documentation : Ce document architecture comme référence unique

### Pattern Examples

**Good Examples:**

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :professor
  belongs_to :scraped_url

  # Enums
  enum type_event: { atelier: 0, stage: 1 }

  # Validations
  validates :date_debut, :date_fin, :titre, presence: true
  validates :prix_normal, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :prix_reduit, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :date_fin_apres_debut
  validate :format_compatible_coherent

  # Callbacks
  before_save :calculate_duration

  # Scopes
  scope :futurs, -> { where('date_debut > ?', Time.current) }
  scope :gratuits, -> { where(gratuit: true) }
  scope :en_ligne, -> { where(en_ligne: true) }
  scope :presentiel, -> { where(en_presentiel: true) }

  private

  def calculate_duration
    if date_debut.present? && date_fin.present?
      self.duree_minutes = ((date_fin - date_debut) / 60).to_i
    end
  end

  def date_fin_apres_debut
    if date_debut.present? && date_fin.present? && date_fin <= date_debut
      errors.add(:date_fin, "doit être après la date de début")
    end
  end

  def format_compatible_coherent
    if !en_ligne && !en_presentiel
      errors.add(:base, "L'événement doit être en ligne ou en présentiel (ou les deux)")
    end
  end
end

# Migration example
class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :titre, null: false
      t.text :description
      t.string :tags, array: true, default: []
      t.datetime :date_debut, null: false
      t.datetime :date_fin, null: false
      t.integer :duree_minutes
      t.string :lieu
      t.text :adresse_complete
      t.decimal :prix_normal, precision: 8, scale: 2
      t.decimal :prix_reduit, precision: 8, scale: 2
      t.integer :type_event, default: 0, null: false
      t.boolean :gratuit, default: false, null: false
      t.boolean :en_ligne, default: false, null: false
      t.boolean :en_presentiel, default: true, null: false
      t.references :professor, null: false, foreign_key: true
      t.references :scraped_url, null: true, foreign_key: true  # nullable pour events créés/corrigés manuellement

      t.timestamps
    end

    add_index :events, :date_debut
    add_index :events, :gratuit
    add_index :events, :type_event
  end
end

# Migration EventSource
class CreateEventSources < ActiveRecord::Migration[8.0]
  def change
    create_table :event_sources do |t|
      t.references :event, null: false, foreign_key: true
      t.references :scraped_url, null: false, foreign_key: true
      t.boolean :primary_source, default: false

      t.timestamps
    end

    add_index :event_sources, [:event_id, :scraped_url_id], unique: true
  end
end

# config/initializers/timezone.rb
Rails.application.configure do
  config.time_zone = "Europe/Paris"
  # IMPORTANT : garder :utc en base (défaut Rails).
  # Rails convertit automatiquement vers Europe/Paris à l'affichage
  # grâce à config.time_zone ci-dessus.
  # Stocker en local causerait des bugs aux changements d'heure été/hiver.
  config.active_record.default_timezone = :utc
end
```

**Anti-Patterns:**

```ruby
# ❌ MAUVAIS : camelCase, pas de validation timezone, calcul manuel durée
class Event < ApplicationRecord
  validates :dateDebut, presence: true  # ❌ camelCase
  # ❌ Manque validation timezone Europe/Paris
  # ❌ Manque callback calculate_duration automatique
  # ❌ Manque validation date_fin > date_debut
  # ❌ Manque validation format compatible (en_ligne ou en_presentiel)
end

# ❌ MAUVAIS : durée calculée manuellement ailleurs
def create
  event = Event.new(event_params)
  event.duree_minutes = params[:duree_minutes]  # ❌ Input manuel au lieu de calcul auto
  event.save
end

# ❌ MAUVAIS : Pas de retry sur jobs
class ScrapingJob < ApplicationJob
  def perform(scraped_url_id)
    # ❌ Pas de retry_on configuré
    ScrapingEngine.fetch(scraped_url_id)
  end
end
```

## Project Structure & Boundaries

### Complete Project Directory Structure

```
3graces-v2/
├── README.md
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── config.ru
├── .env (pas commité, voir .env.example)
├── .env.example
├── .gitignore
├── .ruby-version
├── docker-compose.yml
├── Dockerfile
├── Caddyfile
├── .claude/
│   └── settings.json (permissions headless mode agent autonome)
│
├── app/
│   ├── assets/
│   │   ├── config/
│   │   │   └── manifest.js
│   │   ├── images/
│   │   ├── stylesheets/
│   │   │   └── application.tailwind.css
│   │   └── javascripts/
│   │       ├── application.js
│   │       └── controllers/
│   │           ├── application.js
│   │           ├── filters_controller.js
│   │           ├── mobile_drawer_controller.js (navigation mobile)
│   │           └── carousel_controller.js (hero section)
│   │
│   ├── controllers/
│   │   ├── admin/
│   │   │   ├── application_controller.rb (HTTP Basic Auth)
│   │   │   ├── scraped_urls_controller.rb (CRUD URLs)
│   │   │   ├── change_logs_controller.rb (lecture seule)
│   │   │   └── events_controller.rb (lecture + correction)
│   │   ├── application_controller.rb
│   │   ├── concerns/
│   │   │   └── seo_metadata.rb
│   │   ├── pages_controller.rb (home, about, contact)
│   │   ├── events_controller.rb
│   │   ├── professors_controller.rb
│   │   ├── newsletters_controller.rb
│   │   └── sitemaps_controller.rb
│   │
│   ├── helpers/
│   │   ├── application_helper.rb
│   │   ├── events_helper.rb
│   │   ├── seo_helper.rb
│   │   └── timezone_helper.rb
│   │
│   ├── jobs/
│   │   ├── application_job.rb
│   │   ├── scraping_job.rb (cron 24h)
│   │   ├── event_update_job.rb
│   │   └── alert_email_job.rb
│   │
│   ├── mailers/
│   │   ├── application_mailer.rb
│   │   └── alert_mailer.rb
│   │
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── concerns/
│   │   │   └── timezone_validatable.rb
│   │   ├── event.rb
│   │   ├── professor.rb
│   │   ├── scraped_url.rb
│   │   ├── change_log.rb
│   │   └── newsletter.rb
│   │
│   └── views/
│       ├── layouts/
│       │   ├── application.html.erb
│       │   ├── _head_meta.html.erb (SEO meta tags)
│       │   ├── _navbar.html.erb (desktop)
│       │   └── _mobile_drawer.html.erb (navigation mobile)
│       ├── pages/
│       │   ├── home.html.erb (hero + CTA)
│       │   ├── about.html.erb
│       │   └── contact.html.erb
│       ├── events/
│       │   ├── index.html.erb
│       │   ├── show.html.erb
│       │   └── _event_card.html.erb
│       ├── professors/
│       │   ├── show.html.erb
│       │   └── stats.html.erb
│       ├── newsletters/
│       │   └── create.html.erb
│       ├── shared/
│       │   ├── _filters.html.erb
│       │   ├── _loading.html.erb
│       │   ├── _flash.html.erb
│       │   └── _hero.html.erb (carousel photos danse)
│       └── admin/
│           ├── layouts/
│           │   └── admin.html.erb
│           ├── scraped_urls/ (index, show, new, edit, _form)
│           ├── change_logs/ (index, show)
│           └── events/ (index, show, edit)
│
├── config/
│   ├── application.rb
│   ├── boot.rb
│   ├── cable.yml
│   ├── credentials.yml.enc
│   ├── database.yml
│   ├── environment.rb
│   ├── importmap.rb
│   ├── puma.rb
│   ├── routes.rb
│   ├── storage.yml
│   ├── environments/
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   ├── initializers/
│   │   ├── assets.rb
│   │   ├── content_security_policy.rb
│   │   ├── filter_parameter_logging.rb
│   │   ├── inflections.rb
│   │   ├── permissions_policy.rb
│   │   ├── solid_queue.rb (config cron + queues)
│   │   ├── timezone.rb (force Europe/Paris)
│   │   └── rack_attack.rb (rate limiting)
│   └── locales/
│       └── fr.yml
│
├── db/
│   ├── migrate/
│   │   ├── 20260325_create_professors.rb
│   │   ├── 20260325_create_scraped_urls.rb
│   │   ├── 20260325_create_professor_scraped_urls.rb (join model)
│   │   ├── 20260325_create_events.rb
│   │   ├── 20260325_create_event_sources.rb
│   │   ├── 20260325_create_change_logs.rb
│   │   └── 20260325_create_newsletters.rb
│   ├── schema.rb
│   └── seeds.rb
│
├── lib/
│   ├── scraping_engine.rb (orchestrateur scraping)
│   ├── scrapers/
│   │   ├── html_scraper.rb (sites HTML classiques)
│   │   ├── google_calendar_scraper.rb (Google Calendar)
│   │   ├── helloasso_scraper.rb (Helloasso billetterie)
│   │   └── billetweb_scraper.rb (Billetweb billetterie)
│   ├── claude_cli_integration.rb
│   ├── html_differ.rb
│   ├── alert_mailer_service.rb
│   └── tasks/
│       └── scraping.rake (tâches rake manuelles)
│
├── log/
│   ├── development.log
│   ├── production.log
│   ├── scraping.log (logs spécifiques scraping)
│   └── test.log
│
├── public/
│   ├── 404.html
│   ├── 422.html
│   ├── 500.html
│   ├── favicon.ico
│   ├── robots.txt
│   └── assets/ (assets compilés Propshaft)
│
├── storage/ (Active Storage, si utilisé pour avatars profs)
│
├── test/
│   ├── test_helper.rb
│   ├── models/
│   │   ├── event_test.rb
│   │   ├── professor_test.rb
│   │   ├── scraped_url_test.rb
│   │   ├── change_log_test.rb
│   │   └── newsletter_test.rb
│   ├── controllers/
│   │   ├── events_controller_test.rb
│   │   ├── professors_controller_test.rb
│   │   └── newsletters_controller_test.rb
│   ├── jobs/
│   │   ├── scraping_job_test.rb
│   │   └── event_update_job_test.rb
│   ├── integration/
│   │   ├── event_browsing_test.rb
│   │   ├── filters_test.rb
│   │   └── newsletter_subscription_test.rb
│   ├── services/
│   │   ├── scraping_engine_test.rb
│   │   ├── scrapers/
│   │   │   ├── html_scraper_test.rb
│   │   │   ├── google_calendar_scraper_test.rb
│   │   │   ├── helloasso_scraper_test.rb
│   │   │   └── billetweb_scraper_test.rb
│   │   ├── claude_cli_integration_test.rb
│   │   └── html_differ_test.rb
│   ├── fixtures/
│   │   ├── events.yml
│   │   ├── professors.yml
│   │   └── scraped_urls.yml
│   └── mocks/
│       ├── claude_cli_response.json
│       └── scraped_html_samples/ (HTML samples pour tests scrapers)
│
├── tmp/
│   ├── cache/
│   ├── pids/
│   ├── sockets/
│   └── storage/
│
├── vendor/ (gems vendorisées si nécessaire)
│
├── docs/ (documentation projet)
│   ├── brief.md
│   ├── prd.md
│   └── ui-reference.md (screenshots + spécifications design)
│
└── _bmad-output/ (artefacts BMAD)
    ├── planning-artifacts/
    │   └── architecture.md (ce document)
    └── implementation-artifacts/
```

### Architectural Boundaries

**API Boundaries :**
- Pas d'API publique exposée pour MVP
- Communication interne : Controllers ↔ Models ↔ Jobs ↔ Services (lib/)

**Component Boundaries :**
- **Frontend** : Views ERB + Partials + Stimulus controllers (interactions JS légères)
- **Backend** : Controllers (orchestration) → Services (logique métier complexe) → Models (persistance + validations)
- **Jobs** : Solid Queue jobs isolés pour scraping automatisé
- **Services** : `lib/` pour logique réutilisable complexe (scraping, Claude CLI, diff HTML)
- **Scrapers** : `lib/scrapers/` scrapers spécialisés par format (HTML, Google Calendar, Helloasso, Billetweb)

**Service Boundaries :**
- `ScrapingEngine` : Orchestrateur qui délègue aux scrapers spécialisés selon type URL
- `HtmlScraper` : Scraping sites HTML classiques (détection via content-type)
- `GoogleCalendarScraper` : Scraping Google Calendar (détection via URL pattern)
- `HelloassoScraper` : Scraping Helloasso billetterie (détection via URL pattern)
- `BilletwebScraper` : Scraping Billetweb billetterie (détection via URL pattern)
- `ClaudeCliIntegration` : Invocation CLI headless + parsing réponse
- `HtmlDiffer` : Calcul diff entre versions HTML
- `AlertMailerService` : Envoi alertes email admin

**Data Boundaries :**
- PostgreSQL : Source unique de vérité
- Fragment caching Rails : Cache invalidé post-scraping
- Pas de Redis pour MVP (in-memory cache suffit)

### Requirements to Structure Mapping

**Pages Statiques (Homepage, About, Contact) :**
- Controllers: `app/controllers/pages_controller.rb`
- Views: `app/views/pages/home.html.erb`, `app/views/pages/about.html.erb`, `app/views/pages/contact.html.erb`
- Partials: `app/views/shared/_hero.html.erb`, `app/views/layouts/_navbar.html.erb`, `app/views/layouts/_mobile_drawer.html.erb`
- Stimulus: `app/assets/javascripts/controllers/carousel_controller.js`, `app/assets/javascripts/controllers/mobile_drawer_controller.js`

**FR Catégorie 1-11 (Découverte Événements) :**
- Controllers: `app/controllers/events_controller.rb`, `app/controllers/concerns/seo_metadata.rb`
- Models: `app/models/event.rb`, `app/models/professor.rb`
- Views: `app/views/events/`, `app/views/shared/_filters.html.erb`
- Helpers: `app/helpers/events_helper.rb`, `app/helpers/seo_helper.rb`
- Stimulus: `app/assets/javascripts/controllers/filters_controller.js`

**FR 14-20 (Scraping Automatisé) :**
- Jobs: `app/jobs/scraping_job.rb`, `app/jobs/event_update_job.rb`
- Services: `lib/scraping_engine.rb` (orchestrateur)
- Scrapers: `lib/scrapers/html_scraper.rb`, `lib/scrapers/google_calendar_scraper.rb`, `lib/scrapers/helloasso_scraper.rb`, `lib/scrapers/billetweb_scraper.rb`
- Support: `lib/html_differ.rb`, `lib/claude_cli_integration.rb`
- Models: `app/models/scraped_url.rb`, `app/models/change_log.rb`

**FR 21-25 (Admin & Monitoring) :**
- Controllers: `app/controllers/admin/application_controller.rb`, `app/controllers/admin/scraped_urls_controller.rb`, `app/controllers/admin/change_logs_controller.rb`, `app/controllers/admin/events_controller.rb`
- Views: `app/views/admin/scraped_urls/`, `app/views/admin/change_logs/`, `app/views/admin/events/`
- Logs: `log/scraping.log`, `log/production.log`
- Services: `lib/alert_mailer_service.rb`
- Mailers: `app/mailers/alert_mailer.rb`
- Jobs: `app/jobs/alert_email_job.rb`
- Auth: HTTP Basic Auth natif Rails (credentials `.env`)

**FR 26-29 (Stats Profs) :**
- Controllers: `app/controllers/professors_controller.rb#stats`
- Models: `app/models/professor.rb` (compteurs `consultations_count`, `clics_sortants_count`)
- Views: `app/views/professors/stats.html.erb`

**FR 30-34 (SEO) :**
- Helpers: `app/helpers/seo_helper.rb`
- Concerns: `app/controllers/concerns/seo_metadata.rb`
- Views: `app/views/layouts/_head_meta.html.erb`
- Controllers: `app/controllers/sitemaps_controller.rb`

**FR 12-13 (Newsletter) :**
- Controllers: `app/controllers/newsletters_controller.rb`
- Models: `app/models/newsletter.rb`
- Views: `app/views/newsletters/create.html.erb`

**Cross-Cutting Concerns :**

**Timezone Europe/Paris :**
- Config: `config/initializers/timezone.rb`
- Helper: `app/helpers/timezone_helper.rb`
- Concern: `app/models/concerns/timezone_validatable.rb`
- Impact: Tous les models avec timestamps

**Error Handling & Retry :**
- Base: `app/jobs/application_job.rb` (retry_on configuré)
- Logs: `log/scraping.log` (erreurs structurées)
- Service: `lib/alert_mailer_service.rb` (alertes > 3 cycles échoués)

**Rate Limiting :**
- Config: `config/initializers/rack_attack.rb`
- Impact: Toutes les requêtes HTTP entrantes

### Integration Points

**Internal Communication :**
1. Controllers → Models (ActiveRecord queries)
2. Controllers → Jobs (Solid Queue enqueue via `perform_later`)
3. Jobs → Services (`lib/scrapers/*`) → Models
4. Services → External (Claude CLI via shell exec)
5. `ScrapingEngine` → Scrapers spécialisés (pattern strategy selon type URL)

**External Integrations :**
- **Claude Code CLI** : Shell exec depuis `lib/claude_cli_integration.rb` avec flag `--dangerously-skip-permissions`
- **SMTP** : Action Mailer pour alertes email admin (`AlertMailer`)
- **Let's Encrypt** : Caddy reverse proxy (auto-renew HTTPS, config `Caddyfile`)
- **Sites scrapés** : HTTP GET via `Net::HTTP` ou `HTTParty` gem, respect robots.txt (NFR-S1)

**Data Flow :**

```
Cycle scraping automatisé (cron 24h) :
1. Cron trigger → ScrapingJob.perform_later (toutes ScrapedUrl actives)
2. ScrapingJob → ScrapingEngine.process(scraped_url)
3. ScrapingEngine détecte type URL → délègue au scraper spécialisé
   - URL contient "calendar.google.com" → GoogleCalendarScraper
   - URL contient "helloasso.com" → HelloassoScraper
   - URL contient "billetweb.fr" → BilletwebScraper
   - Sinon → HtmlScraper (défaut)
4. Scraper.fetch → Retourne HTML/JSON brut
5. HtmlDiffer.compare(old_html, new_html) → Changements détectés ?
6. Si changements :
   - ChangeLog.create(scraped_url, diff_html)
   - EventUpdateJob.perform_later(scraped_url_id)
7. EventUpdateJob → ClaudeCliIntegration.parse_and_generate(scraped_url, html, notes_correctrices)
8. Claude CLI parse → Retourne JSON structuré (events array)
9. Events créés/mis à jour en base (Event.create_or_update_from_scrape)
10. Fragment cache events invalidé
11. Si erreur critique (3 cycles échoués) → AlertEmailJob.perform_later → AlertMailer.critical_error(scraped_url)
```

**Flux utilisateur consulte événements :**
```
1. User → GET /evenements
2. EventsController#index → Event.futurs.includes(:professor)
3. Fragment cache hit ? → Return cached HTML
4. Sinon → Render events/index.html.erb avec Turbo Frames
5. User applique filtres → Stimulus filters_controller.js
6. Turbo Frame request → EventsController#index?gratuit=true&date_debut=...
7. SQL query filtrée → Render partial _event_card pour chaque event
8. User clique event → GET /evenements/:slug
9. EventsController#show → Professor.increment_counter(:consultations_count, professor_id) # Atomic
10. Render events/show.html.erb avec meta tags SEO (Schema.org Event)
11. User clique "Site du prof" → Professor.increment_counter(:clics_sortants_count, professor_id) # Atomic (via route intermédiaire ou JS beacon)
12. Redirect externe vers site prof
```

### File Organization Patterns

**Configuration Files :**
- Root : `.env.example`, `docker-compose.yml`, `Dockerfile`, `Caddyfile`, `.ruby-version`
- Rails config : `config/*.rb`, `config/initializers/*.rb`, `config/environments/*.rb`
- Claude Code : `.claude/settings.json` (permissions headless mode agent autonome)
- Database : `config/database.yml`, `db/schema.rb`

**Source Organization :**
- **MVC Rails standard** : `app/models/`, `app/controllers/`, `app/views/`
- **Business logic complexe** : `lib/` (services réutilisables)
- **Scrapers spécialisés** : `lib/scrapers/` (un fichier par format)
- **Background jobs** : `app/jobs/`
- **Frontend interactivité** : `app/assets/javascripts/controllers/` (Stimulus)

**Test Organization :**
- **Unit tests** : `test/models/`, `test/services/`, `test/services/scrapers/`
- **Controller tests** : `test/controllers/`
- **Job tests** : `test/jobs/`
- **Integration tests** : `test/integration/`
- **Fixtures** : `test/fixtures/` (YAML)
- **Mocks** : `test/mocks/` (JSON samples, HTML samples scrapers)

**Asset Organization :**
- **Stylesheets** : `app/assets/stylesheets/` (Tailwind CSS)
- **JavaScript** : `app/assets/javascripts/` (Stimulus controllers)
- **Images** : `app/assets/images/`
- **Compiled assets** : `public/assets/` (Propshaft output, cache-busted)

### Development Workflow Integration

**Development Server Structure :**
- `rails server` : Puma sur port 3000 (défaut)
- Hot reload : Rails reloader automatique (code changes)
- Logs console : `tail -f log/development.log`
- Jobs processing : Solid Queue inline mode en développement

**Build Process Structure :**
- **Assets** : Propshaft compile `app/assets/` → `public/assets/` avec fingerprinting
- **CSS** : Tailwind CSS JIT compile via `tailwindcss-rails` gem
- **JS** : Import maps (pas de bundler), fichiers servis directement

**Deployment Structure :**
- **Docker Compose** : 3 containers (Rails app, PostgreSQL, Caddy)
- **Volumes** :
  - `~/.claude:/root/.claude` (auth Claude CLI persistante)
  - `./db:/var/lib/postgresql/data` (PostgreSQL data)
  - `./log:/app/log` (logs accessibles host)
- **Caddy reverse proxy** : HTTPS automatique Let's Encrypt, reverse proxy vers Rails:3000
- **Backups** : Cron host exécute `docker exec postgres pg_dump` quotidien
- **Solid Queue** : Mode production avec workers dédiés (config `config/initializers/solid_queue.rb`)

**Manual Scraping Tasks :**
- `rake scraping:run_all` : Scrape toutes les URLs actives (enqueue tous les ScrapingJob)
- `rake scraping:run[url_id]` : Scrape une URL spécifique par ID
- `rake scraping:test[url_id]` : Dry-run test scraping sans écrire en DB (important pour tester scrapers sans polluer données)
- Fichier : `lib/tasks/scraping.rake`

## Admin Interface (Minimal)

### Admin Authentication & Routes

**HTTP Basic Auth (Rails natif, pas de gem externe) :**
- Route protégée : `/admin`
- Credentials stockées dans `.env` : `ADMIN_USERNAME`, `ADMIN_PASSWORD`
- Protection via `http_basic_authenticate_with` dans `Admin::ApplicationController`

### Admin Controllers

```
app/controllers/admin/
├── application_controller.rb (HTTP Basic Auth + before_action)
├── scraped_urls_controller.rb (CRUD URLs + notes correctrices)
├── change_logs_controller.rb (lecture seule, liste des changements détectés)
└── events_controller.rb (lecture + correction manuelle si scraping erreur)
```

**Admin::ApplicationController :**
- HTTP Basic Auth via `http_basic_authenticate_with name: ENV['ADMIN_USERNAME'], password: ENV['ADMIN_PASSWORD']`
- Layout admin minimal (pas de design élaboré, HTML/Tailwind basique)

**Admin::ScrapedUrlsController :**
- CRUD complet : index, show, new, create, edit, update, destroy
- Champs éditables : url, notes_correctrices, statut_scraping
- Actions supplémentaires : 
  - `POST /admin/scraped_urls/:id/scrape_now` (trigger scraping manuel immédiat)
  - `GET /admin/scraped_urls/:id/preview` (dry-run test sans écrire DB)

**Admin::ChangeLogsController :**
- Lecture seule : index (liste paginée), show (détails diff HTML)
- Filtres : par scraped_url, par date
- Affichage diff HTML formaté (avant/après)

**Admin::EventsController :**
- Lecture principale + correction manuelle si scraping génère erreurs
- Actions : index, show, edit, update (correction manuelle titres/dates/prix si Claude CLI parse mal)
- Pas de création manuelle (events créés uniquement via scraping)

### Admin Views

```
app/views/admin/
├── layouts/
│   └── admin.html.erb (layout minimal, Tailwind basique)
├── scraped_urls/
│   ├── index.html.erb (liste URLs avec statut scraping)
│   ├── show.html.erb (détails URL + notes correctrices + change_logs associés)
│   ├── new.html.erb (formulaire ajout URL)
│   ├── edit.html.erb (formulaire édition URL + notes correctrices)
│   └── _form.html.erb (partial formulaire)
├── change_logs/
│   ├── index.html.erb (liste changements détectés, paginée)
│   └── show.html.erb (détails diff HTML avant/après)
└── events/
    ├── index.html.erb (liste events avec filtres)
    ├── show.html.erb (détails event)
    └── edit.html.erb (correction manuelle si parse erreur)
```

**Design admin :**
- Pas de design élaboré : HTML sémantique + Tailwind CSS classes utilitaires basiques
- Tables simples pour listes, formulaires Rails standards
- Flash messages pour feedbacks (success, error)
- Pagination simple avec `pagy` gem (ou Kaminari)

### Admin Routes

```ruby
# config/routes.rb
namespace :admin do
  resources :scraped_urls do
    member do
      post :scrape_now
      get :preview
    end
  end
  resources :change_logs, only: [:index, :show]
  resources :events, only: [:index, :show, :edit, :update]
  
  root to: 'scraped_urls#index'
end
```

### Admin Environment Variables

```bash
# .env
ADMIN_USERNAME=admin
ADMIN_PASSWORD=secret_password_here
```

**Security :**
- HTTP Basic Auth natif Rails (pas de session, pas de cookies)
- Credentials jamais commitées (`.env` dans `.gitignore`)
- HTTPS forcé via Caddy (TLS 1.3) → credentials chiffrées en transit

### Admin Use Cases

**Journey Admin (Duy) :**
1. Accès `/admin` → Prompt HTTP Basic Auth browser
2. Entre credentials `.env` → Accès admin interface
3. **Ajout nouvelle URL à scraper** : `/admin/scraped_urls/new` → Form URL + notes correctrices → Create
4. **Test scraping dry-run** : `/admin/scraped_urls/:id/preview` → Affiche résultat parsing sans écrire DB
5. **Trigger scraping manuel** : `/admin/scraped_urls/:id/scrape_now` → Job enqueued immédiatement
6. **Consulter changements détectés** : `/admin/change_logs` → Liste diffs HTML récents
7. **Corriger event mal parsé** : `/admin/events/:id/edit` → Corrige titre/date/prix manuellement → Update

**Rationale :**
- Interface admin minimaliste évite surcharge développement (contrainte nouveau papa disponibilité limitée)
- HTTP Basic Auth natif Rails suffit (pas de gem externe, sécurité TLS 1.3 via Caddy)
- CRUD ScrapedUrls permet ajout/édition URLs sans toucher DB directement
- Dry-run preview permet tester scrapers avant activation
- Correction manuelle events permet fixer erreurs parsing Claude CLI sans re-scraper


## Architecture Validation Results

### Coherence Validation ✅

**Decision Compatibility:**
- Rails 8.1.2 + PostgreSQL + Solid Queue + Tailwind + Caddy : Stack cohérente, toutes compatibles
- HTTP Basic Auth natif Rails : Pas de gem externe, sécurité TLS 1.3 via Caddy
- Claude Code CLI headless : Compatible shell exec depuis Ruby
- Scrapers spécialisés (HTML, Google Calendar, Helloasso, Billetweb) : Pattern strategy compatible ScrapingEngine
- Pas de conflits identifiés

**Pattern Consistency:**
- Naming conventions Rails (snake_case DB/code, PascalCase classes) cohérentes avec stack
- Timezone Europe/Paris uniforme : Forcée au niveau config + validations
- Retry exponentiel 3x Solid Queue : Pattern standard Rails jobs
- Fragment caching Rails : Compatible performance targets (LCP < 2.5s)
- HTTP Basic Auth admin : Cohérent avec simplicité stack (pas de sessions complexes)

**Structure Alignment:**
- Structure MVC Rails standard supporte toutes les décisions
- Namespace `Admin::` pour controllers/views admin : Isolation claire
- `lib/scrapers/` spécialisés : Pattern strategy cohérent avec ScrapingEngine
- Turbo Frames pour filtres : Aligné avec MPA + Stimulus
- `.claude/settings.json` : Supporte mode agent autonome headless

### Requirements Coverage Validation ✅

**Functional Requirements Coverage (40 FR - MVP) :**
- FR1-11 (Événements) : ✅ EventsController + filtres Turbo
- FR12-13 (Newsletter) : ✅ Newsletter model + NewslettersController
- FR14-20 (Scraping) : ✅ ScrapingJob + scrapers spécialisés + Claude CLI + HtmlDiffer
- FR21-25 (Admin & Monitoring) : ✅ Admin namespace (ScrapedUrls CRUD, ChangeLogs lecture, Events correction) + HTTP Basic Auth + logs + alertes email
- FR26-29 (Stats profs) : ✅ Compteurs + ProfessorsController#stats
- FR30-34 (SEO) : ✅ seo_helper + Schema.org + sitemap
- FR35-37 (PWA) : ⏸️ POST-MVP (manifest + service worker)
- FR38-40 (Accessibilité) : ✅ HTML sémantique + WCAG 2.1 AA patterns
- FR41 (Préférences mode sombre) : ⏸️ POST-MVP

**Non-Functional Requirements Coverage (19 NFR) :**
- NFR-P1-P5 (Performance) : ✅ Turbo + fragment caching + lazy loading + WebP
- NFR-S1-S4 (Security) : ✅ Robots.txt + RGPD + HTTPS TLS 1.3 + user-agent bot
- NFR-R1-R7 (Reliability) : ✅ Retry 3x + alertes < 15min + backups 30j
- NFR-A1-A4 (Accessibilité) : ✅ WCAG 2.1 AA + Lighthouse > 90
- NFR-I1-I6 (Integration) : ✅ Claude CLI + Solid Queue + timezone Europe/Paris
- NFR-M1-M3 (Maintainability) : ✅ Logs 90j + README + Docker
- NFR-SC1-SC2 (Scalability) : ✅ Single server + caching (500 events supportés)

**Coverage : 100% des FR et NFR architecturalement supportés**

### Implementation Readiness Validation ✅

**Decision Completeness:**
- Stack Rails 8.1.2 + PostgreSQL + Solid Queue + Tailwind + Caddy : Versions spécifiées
- Admin HTTP Basic Auth : Credentials `.env`, pas de gem externe
- Models complets : Validations + callbacks + scopes (Event example)
- Scrapers spécialisés : 4 scrapers (HTML, Google Calendar, Helloasso, Billetweb)
- Claude CLI : Flag `--dangerously-skip-permissions` + volume `~/.claude`
- Exemples code fournis (Event model, migration, anti-patterns, admin routes)

**Structure Completeness:**
- Structure complète avec admin namespace : `app/controllers/admin/`, `app/views/admin/`
- Admin controllers : ApplicationController (auth), ScrapedUrlsController (CRUD), ChangeLogsController (lecture), EventsController (correction)
- Scrapers : `lib/scrapers/` (4 spécialisés)
- Rake tasks : `lib/tasks/scraping.rake` (run_all, run[id], test[id] dry-run)
- Tests admin : `test/controllers/admin/` pour coverage

**Pattern Completeness:**
- Admin auth : HTTP Basic Auth natif Rails (`http_basic_authenticate_with`)
- Admin actions : CRUD URLs + dry-run preview + scrape_now trigger manuel
- Dry-run : `rake scraping:test[id]` + `/admin/scraped_urls/:id/preview`
- Correction manuelle : Admin::EventsController#edit pour fixer erreurs parsing
- Timestamps : Timezone Europe/Paris forcée partout

### Gap Analysis Results

**Aucun gap critique identifié**

**Améliorations futures (post-MVP) :**
- Chiffrement AES-256 emails newsletter
- Scraping Instagram/Facebook (authentification requise)
- Algolia search + géolocalisation
- CI/CD automatisé
- Monitoring externe (Sentry, Datadog)
- Admin interface plus élaborée (dashboard stats scraping, graphiques)

### Architecture Completeness Checklist

**✅ Requirements Analysis**
- [x] Project context thoroughly analyzed (PRD 41 FR + 19 NFR, Brief)
- [x] Scale and complexity assessed (Medium, 8-10 composants + admin interface)
- [x] Technical constraints identified (Stack Rails imposée, timezone Europe/Paris, Claude CLI headless)
- [x] Cross-cutting concerns mapped (timezone, mode clair/sombre, error handling, rate limiting, admin auth)

**✅ Architectural Decisions**
- [x] Critical decisions documented with versions (Rails 8.1.2, PostgreSQL, Caddy, Solid Queue)
- [x] Technology stack fully specified (Rails MPA + Turbo + Stimulus + Tailwind + Docker)
- [x] Integration patterns defined (ScrapingEngine → scrapers, Claude CLI shell exec, HTTP Basic Auth admin)
- [x] Performance considerations addressed (fragment caching, Turbo, lazy loading, WebP)

**✅ Implementation Patterns**
- [x] Naming conventions established (Rails snake_case/PascalCase, routes français, admin namespace)
- [x] Structure patterns defined (MVC + admin namespace + `lib/scrapers/`)
- [x] Communication patterns specified (Solid Queue jobs, Turbo Streams)
- [x] Process patterns documented (retry 3x, logs structurés, dry-run, admin correction manuelle)

**✅ Project Structure**
- [x] Complete directory structure defined (avec admin controllers/views)
- [x] Component boundaries established (Frontend/Backend/Jobs/Services/Scrapers/Admin)
- [x] Integration points mapped (data flows scraping + admin CRUD + user consultation)
- [x] Requirements to structure mapping complete (FR → fichiers spécifiques incluant admin)

### Architecture Readiness Assessment

**Overall Status:** ✅ **READY FOR IMPLEMENTATION**

**Confidence Level:** **HIGH**

**Key Strengths:**
1. **Automatisation maximale** : Scraping cron 24h + retry + alertes → 99% autonomie 30j
2. **Admin minimaliste** : HTTP Basic Auth natif + CRUD URLs + dry-run preview + correction manuelle events → aucune gem externe
3. **Scrapers spécialisés** : Pattern strategy extensible (Instagram/Facebook post-MVP)
4. **Dry-run multi-niveaux** : `rake scraping:test[id]` + `/admin/scraped_urls/:id/preview` → tests sûrs sans polluer DB
5. **Timezone uniforme** : Europe/Paris forcée partout → évite bugs conversion horaire
6. **Simplicité stack** : Rails MPA + Turbo + HTTP Basic Auth → maintenabilité élevée pour admin solo

**Areas for Future Enhancement:**
- Dashboard admin stats scraping (taux succès, erreurs récentes, graphiques)
- CI/CD pipeline automatisé (GitHub Actions)
- Monitoring externe (Sentry errors, Datadog metrics)
- Horizontal scaling (load balancer + multiple containers)
- Algolia search full-text + géolocalisation
- Interface admin plus élaborée (design moderne, filtres avancés)

### Implementation Handoff

**AI Agent Guidelines:**
1. **TOUJOURS** respecter timezone Europe/Paris (config + validations)
2. **TOUJOURS** calculer `duree_minutes` automatiquement via callback (jamais input manuel)
3. **TOUJOURS** utiliser retry exponentiel 3x sur jobs Solid Queue
4. **TOUJOURS** logger avec format structuré `{context}` pour traçabilité
5. **TOUJOURS** respecter relations DB (has_many :through professor_scraped_urls, foreign keys)
6. **TOUJOURS** utiliser scrapers spécialisés via ScrapingEngine (pattern strategy)
7. **TOUJOURS** protéger routes `/admin/*` avec HTTP Basic Auth dans `Admin::ApplicationController`
8. **JAMAIS** créer authentification utilisateur frontend (interface read-only par design)
9. **JAMAIS** utiliser framework JS lourd (Turbo + Stimulus uniquement)
10. **JAMAIS** commiter credentials `.env` (toujours dans `.gitignore`)

**First Implementation Priorities:**
1. Migrations DB (Professor, ScrapedUrl, join table, Event, ChangeLog, Newsletter)
2. Models avec validations + callbacks (`Event.duree_minutes` auto-calculé)
3. HTTP Basic Auth : `Admin::ApplicationController` avec `http_basic_authenticate_with`
4. Admin controllers : ScrapedUrlsController (CRUD + scrape_now + preview), ChangeLogsController, EventsController
5. Admin views basiques (Tailwind minimal, tables simples, formulaires Rails standards)
6. Scrapers spécialisés (`lib/scrapers/`) + ScrapingEngine orchestrateur
7. Solid Queue config (cron 24h + retry 3x)
8. Claude CLI integration avec `--dangerously-skip-permissions`
9. Rake tasks manuelles (run_all, run[id], test[id] dry-run)
10. Routes admin namespace avec actions custom (scrape_now, preview)

---

**✅ Architecture validée et complète. Prête pour implémentation.**

## Addendum: Professor Avatar Storage

### Avatar URL Strategy (MVP)

**Decision:** Option B - URL externe scrapée

**Professor Model:**
```ruby
# app/models/professor.rb
class Professor < ApplicationRecord
  # ... autres attributs
  
  # Avatar
  validates :avatar_url, format: { with: URI::DEFAULT_PARSER.make_regexp(['http', 'https']), allow_blank: true }
  
  # avatar_url (string, nullable) : URL externe scrapée depuis le site du prof
  # Example: "https://site-du-prof.com/images/photo-profil.jpg"
end
```

**Migration:**
```ruby
class CreateProfessors < ActiveRecord::Migration[8.0]
  def change
    create_table :professors do |t|
      t.string :nom, null: false
      t.text :bio
      t.string :site_web
      t.string :email
      t.string :avatar_url # URL externe scrapée
      t.integer :consultations_count, default: 0
      t.integer :clics_sortants_count, default: 0
      
      t.timestamps
    end
  end
end
```

**Scraping Integration:**
- Claude CLI scrape le site du prof → détecte URL image photo profil
- Stocke URL externe dans `professor.avatar_url`
- Affichage frontend : `<img src="<%= @professor.avatar_url %>" loading="lazy" alt="<%= @professor.nom %>">`

**Rationale:**
- **Zéro complexité stockage** : Pas de Active Storage, pas d'upload, pas de S3/Cloudinary pour MVP
- **Mise à jour automatique** : Si le prof change sa photo sur son site → prochain scraping détecte changement → `avatar_url` mis à jour
- **Performance acceptable** : Images lazy loading + cache HTTP navigateur
- **Post-MVP Cloudinary** : Quand trafic augmente → ajouter layer Cloudinary pour fetch/optimize/cache les `avatar_url` externes

**Fallback:**
- Si `avatar_url` null ou URL cassée → afficher avatar placeholder générique (initiales prof sur fond coloré)
- Helper : `avatar_image_tag(professor)` gère fallback automatiquement

**Post-MVP Enhancement:**
- Cloudinary Fetch API : `https://res.cloudinary.com/.../fetch/<avatar_url>` pour optimisation automatique (WebP, resize, cache CDN)
- Pas besoin modifier DB ni scraping → juste wrapper URL dans helper

## Architecture Clarifications & Implementation Notes

### 1. Billetweb Scraper - Data Flow Confirmation

**✅ Billetweb inclus dans détection URL :**

```ruby
# lib/scraping_engine.rb
class ScrapingEngine
  def self.process(scraped_url)
    scraper = detect_scraper(scraped_url.url)
    # ...
  end
  
  private
  
  def self.detect_scraper(url)
    case url
    when /calendar\.google\.com/i
      Scrapers::GoogleCalendarScraper
    when /helloasso\.com/i
      Scrapers::HelloassoScraper
    when /billetweb\.fr/i
      Scrapers::BilletwebScraper
    else
      Scrapers::HtmlScraper # défaut
    end
  end
end
```

**Data flow complet (incluant Billetweb) :**
1. ScrapingJob → ScrapingEngine.process(scraped_url)
2. ScrapingEngine détecte type URL :
   - `calendar.google.com` → GoogleCalendarScraper
   - `helloasso.com` → HelloassoScraper
   - `billetweb.fr` → BilletwebScraper ✅
   - Sinon → HtmlScraper (défaut)
3. Scraper.fetch → HTML/JSON brut
4. Suite du flow identique

### 2. Compteurs Professor - Mécanisme Tracking Frontend

**⚠️ Problème identifié :**
- `Professor.consultations_count` : Incrémenté quand ?
- `Professor.clics_sortants_count` : Nécessite tracking clic externe

**Solutions recommandées (à préciser en story) :**

**Consultations Count :**
```ruby
# app/controllers/professors_controller.rb
def show
  @professor = Professor.find(params[:id])
  Professor.increment_counter(:consultations_count, @professor.id) # Atomic SQL, évite race conditions
  # ...
end
```

**Clics Sortants Count - Option A (Route intermédiaire) :**
```ruby
# config/routes.rb
resources :professors do
  member do
    get :redirect_to_site # /professors/:id/redirect_to_site
  end
end

# app/controllers/professors_controller.rb
def redirect_to_site
  @professor = Professor.find(params[:id])
  Professor.increment_counter(:clics_sortants_count, @professor.id) # Atomic SQL
  redirect_to @professor.site_web, allow_other_host: true, status: :see_other
end

# app/views/events/show.html.erb
<%= link_to "Voir le site du prof", redirect_to_site_professor_path(@event.professor), 
            class: "btn-primary", target: "_blank" %>
```

**Clics Sortants Count - Option B (JS Beacon) :**
```javascript
// app/assets/javascripts/professors_tracking.js
document.addEventListener('turbo:load', () => {
  document.querySelectorAll('[data-professor-outbound]').forEach(link => {
    link.addEventListener('click', (e) => {
      const professorId = link.dataset.professorId;
      
      // Beacon API (fire-and-forget, fonctionne même si page unload)
      navigator.sendBeacon(`/professors/${professorId}/track_click`);
    });
  });
});

// config/routes.rb
resources :professors do
  member do
    post :track_click # Endpoint beacon
  end
end

// app/controllers/professors_controller.rb
def track_click
  @professor = Professor.find(params[:id])
  Professor.increment_counter(:clics_sortants_count, @professor.id) # Atomic SQL
  head :no_content
end

// app/views/events/show.html.erb
<%= link_to "Voir le site du prof", @event.professor.site_web, 
            target: "_blank", 
            data: { professor_outbound: true, professor_id: @event.professor.id } %>
```

**💡 Recommandation : Option A (Route intermédiaire) pour MVP**
- Plus simple à implémenter
- Fonctionne sans JS
- Accessibilité garantie
- Option B (Beacon) pour post-MVP si besoin analytics avancées

---

**Ces clarifications sont notées comme points de décision à résoudre lors de la phase implémentation (Create Story).**

---

## Revision Log

### Révision 1 — 2026-03-25

**CORRECTION 1 (CRITIQUE) — Timezone UTC en base de données :**
- ✅ Changé `config.active_record.default_timezone` de `:local` à `:utc`
- ✅ Ajouté commentaire explicatif pour prévenir bugs DST (changements heure été/hiver)
- ✅ Mis à jour toutes références dans Format Patterns, Cross-Cutting Concerns, Validation, Enforcement Guidelines, Pattern Examples
- **Rationale :** Stocker en UTC évite les bugs aux changements d'heure (heure existe 2x en octobre, n'existe pas en mars). Rails convertit automatiquement vers Europe/Paris à l'affichage via `config.time_zone`.

**CORRECTION 2 — Event.scraped_url_id nullable + EventSource pour multi-sources :**
- ✅ Rendu `Event.scraped_url_id` nullable (`belongs_to :scraped_url, optional: true`)
- ✅ Ajouté modèle `EventSource` (join table pour tracking multi-sources)
- ✅ Ajouté migration `CreateEventSources` avec index unique `[:event_id, :scraped_url_id]`
- ✅ Mis à jour liste migrations
- ✅ Retiré section duplicate dans Architecture Clarifications (problème résolu)
- **Rationale :** Permet création manuelle d'events par admin ET tracking d'events scrapés depuis plusieurs URLs (ateliers co-animés). EventSource trace toutes les sources avec flag `primary_source`.

**CORRECTION 3 — HABTM → has_many :through :**
- ✅ Changé `ScrapedUrl` : `has_and_belongs_to_many :professors` → `has_many :professor_scraped_urls` + `has_many :professors, through: :professor_scraped_urls`
- ✅ Renommé section join table en `ProfessorScrapedUrl` (modèle intermédiaire)
- ✅ Mis à jour migration name de `professors_scraped_urls` à `professor_scraped_urls`
- ✅ Mis à jour enforcement guidelines
- **Rationale :** Modèle join explicite permet extensibilité future (ajout métadonnées : rôle, date association, etc.)

**CORRECTION 4 — Infinite Scroll (pas pagination numérotée) :**
- ✅ Changé "Pagination" → "Infinite Scroll" dans Performance Optimization
- ✅ Retiré mentions de numéros de pages et URLs `/evenements?page=2`
- ✅ Conservé batch 30 événements + Turbo Frames + gem pagy côté serveur
- **Rationale :** UX plus fluide sur mobile, pas de choix de page à faire.

**CORRECTION 5 — Compteurs atomiques SQL :**
- ✅ Remplacé `@professor.increment!(:consultations_count)` par `Professor.increment_counter(:consultations_count, @professor.id)` partout
- ✅ Mis à jour sections : Consultations Count, Clics Sortants (Option A et B), Data Flow
- ✅ Supprimé ligne "⚠️ Décision finale à préciser par Dev agent"
- **Rationale :** `increment_counter` génère SQL atomique `UPDATE ... SET count = count + 1`, évite race conditions en cas de requêtes concurrentes.

**CORRECTION 6 — Différer dark mode en post-MVP :**
- ✅ Retiré "Gestion des Préférences (FR41)" de Requirements Overview
- ✅ Retiré `theme_controller.js` de structure JavaScript
- ✅ Retiré section "Mode Clair/Sombre" de Cross-Cutting Concerns
- ✅ Retiré `theme_controller.js` de FR1-11 mapping
- ✅ Mis à jour FR Coverage : FR41 marqué ⏸️ POST-MVP
- ✅ Retiré composant "Mode clair/sombre" de liste composants principaux
- ✅ Retiré dépendance "Mode clair/sombre appliqué à tous layouts"
- **Rationale :** Simplifier scope MVP, réduire surface d'implémentation initiale.

**CORRECTION 7 — Différer PWA en post-MVP :**
- ✅ Retiré composant "PWA (manifest, service worker)" de liste composants principaux
- ✅ Retiré `pwa_controller.rb` de structure controllers
- ✅ Corrigé structure views (retiré `app/views/pwa/`)
- ✅ Retiré `app/assets/images/icons/` (PWA icons)
- ✅ Retiré `service-worker.js` de structure JavaScript
- ✅ Retiré section "FR 35-37 (PWA)" de Requirements to Structure Mapping
- ✅ Retiré "service worker PWA" et "icons PWA" de Asset Organization
- ✅ Mis à jour FR Coverage : FR35-37 marqué ⏸️ POST-MVP
- **Rationale :** PWA requiert service worker, manifest, icons, cache strategy → complexité non-critique pour MVP. Prioriser scraping + affichage events.

**CORRECTION 8 — Documenter hero et navigation mobile :**
- ✅ Ajouté `mobile_drawer_controller.js` et `carousel_controller.js` à structure JavaScript
- ✅ Ajouté `app/views/pages/` (home.html.erb, about.html.erb, contact.html.erb)
- ✅ Ajouté partials : `_navbar.html.erb`, `_mobile_drawer.html.erb`, `_hero.html.erb` dans layouts/shared
- **Rationale :** Homepage avec hero photo + CTA mentionnés dans Brief, navigation mobile essentielle UX mobile-first.

**CORRECTION 9 — Ajouter PagesController :**
- ✅ Ajouté `pages_controller.rb (home, about, contact)` à structure controllers
- ✅ Ajouté section "Pages Statiques" dans Requirements to Structure Mapping avec tous les fichiers associés
- **Rationale :** Controller nécessaire pour gérer homepage, about, contact (hors Events/Professors).

**Scope MVP Final :**
- ✅ 38 FR actifs (FR35-37 PWA + FR41 dark mode → post-MVP)
- ✅ 11 composants principaux (retiré PWA et dark mode)
- ✅ Focus : Scraping + Events + Admin + SEO + Newsletter + Stats
- ✅ Architecture prête pour implémentation (Create Epics → Stories → Dev)
