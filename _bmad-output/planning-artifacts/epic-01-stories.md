# Epic 1: Infrastructure & Deployment - Stories

Enable the development team to build on a production-ready foundation and deploy to production with full monitoring.

**User Outcome:** Complete development environment + production deployment pipeline with database, jobs orchestration, monitoring, backups, and security.

**FRs covered:** FR51, NFR-T1 à T11, NFR-R1 à R4, NFR-A1 à A2, NFR-O1 à O3, ARCH-1 à ARCH-6, ARCH-11 à ARCH-13, ARCH-15, ARCH-19, ARCH-20, ARCH-25 à ARCH-32, ARCH-34 à ARCH-36

---

## PHASE DÉBUT - Enable UI Development (Stories 1.1-1.3)

### Story 1.1: Database Schema, Models & PostgreSQL Setup

As a developer,
I want PostgreSQL installed locally and all core database migrations and models with validations,
So that the application has a complete data foundation to build features upon.

**Acceptance Criteria:**

**Given** Rails 8.1.2 project exists at /home/dang/3graces-v2
**And** PostgreSQL is NOT installed locally (only runs in Docker v1 containers)
**And** Docker v1 (prod port 3000, dev port 3001) must remain untouched
**And** Nextcloud occupies ports 80/443

**When** I set up PostgreSQL for local development
**Then** PostgreSQL is installed via `sudo apt install postgresql postgresql-contrib`
**And** PostgreSQL user `dang` created as superuser: `sudo -u postgres createuser --superuser dang`
**And** Database `threegraces_v2_development` created: `createdb threegraces_v2_development`
**And** Peer authentication configured (no password required for local user dang)
**And** `config/database.yml` uses standard Rails configuration:
```yaml
development:
  adapter: postgresql
  encoding: unicode
  database: threegraces_v2_development
  pool: 5
  username: dang
  # No password - peer auth

test:
  adapter: postgresql
  encoding: unicode
  database: threegraces_v2_test
  pool: 5
  username: dang
```
**And** Docker v1 containers are NOT affected (no port conflicts, no shared volumes)

**When** I run `rails db:create db:migrate`
**Then** the following 7 tables are created with all columns, indexes, and foreign keys:

**Professors table:**
- Columns: avatar_url (string nullable, external URL), bio (text nullable), site_web (string), email (string), consultations_count (integer default 0), clics_sortants_count (integer default 0), timestamps
- Validations: email format, site_web URL format (bio can be null initially - scraped professors may not have bio)

**ScrapedUrls table:**
- Columns: url (string unique NOT NULL), notes_correctrices (text nullable), derniere_version_html (text nullable), statut_scraping (string default 'actif'), erreurs_consecutives (integer default 0), timestamps
- Validations: url presence, url format, url uniqueness

**ProfessorScrapedUrls join table (has_many :through pattern):**
- Columns: professor_id (FK NOT NULL), scraped_url_id (FK NOT NULL), timestamps
- Indexes: [professor_id], [scraped_url_id]
- Model exists (not HABTM) for future extensibility (e.g., role, date_association metadata)

**Events table:**
- Columns: titre (string NOT NULL), description (text), tags (array default []), date_debut (timestamptz NOT NULL), date_fin (timestamptz NOT NULL), duree_minutes (integer), lieu (string), adresse_complete (text), prix_normal (decimal 8,2), prix_reduit (decimal 8,2 nullable), type_event (integer enum: atelier=0, stage=1), gratuit (boolean default false), en_ligne (boolean default false), en_presentiel (boolean default true), professor_id (FK NOT NULL), scraped_url_id (FK nullable), photo_url (string nullable, external URL scraped by Claude CLI), slug (string), timestamps
- Indexes: date_debut, gratuit, type_event, slug (unique)
- Validations: titre presence, date_fin > date_debut, professor presence
- Callback: before_save calculate duree_minutes from (date_fin - date_debut) in minutes
- Callback: before_validation generate slug from titre + lieu + date_debut (for semantic URLs)

**EventSources join table (multi-source tracking):**
- Columns: event_id (FK NOT NULL), scraped_url_id (FK NOT NULL), primary_source (boolean default false), timestamps
- Unique index: [:event_id, :scraped_url_id]

**ChangeLogs table:**
- Columns: diff_html (text), changements_detectes (jsonb), scraped_url_id (FK NOT NULL), timestamps
- Index: [scraped_url_id], [created_at]

**Newsletters table:**
- Columns: email (string unique NOT NULL), consenti_at (timestamp), actif (boolean default true), timestamps
- Validations: email format, email uniqueness

**And** all models have proper associations:
- Professor has_many :professor_scraped_urls, has_many :scraped_urls through: :professor_scraped_urls, has_many :events
- ScrapedUrl has_many :professor_scraped_urls, has_many :professors through: :professor_scraped_urls, has_many :events, has_many :change_logs
- Event belongs_to :professor, belongs_to :scraped_url (optional: true), has_many :event_sources, has_many :additional_scraped_urls through: :event_sources, source: :scraped_url
- EventSource belongs_to :event, belongs_to :scraped_url

**And** Event model has scope `Event.futurs` using `where('date_debut >= ?', Time.current)` for hiding past events (uses Time.current not Date.current - so events at 20h don't disappear at midnight, only when the time has actually passed)
**And** `rails db:migrate:status` shows all 7 migrations as "up"

---

### Story 1.2: Realistic Seed Data for UI Development

As a developer,
I want realistic seed data with 15-20 future events, 5-6 past events, and 3-4 professors,
So that I can develop the UI and test the "hide past events" feature without waiting for the scraping engine.

**Acceptance Criteria:**

**Given** all database tables and models exist from Story 1.1
**When** I run `rails db:seed`
**Then** the database contains:

**3-4 Professor records:**
- Realistic French names (e.g., "Sophie Marchand", "Jean-Luc Dubois", "Marie Fontaine", "Pierre Lefebvre")
- French bios (150-300 characters describing dance practice)
- Valid site_web URLs (e.g., http://example.com/sophie-marchand)
- Valid email addresses
- avatar_url with external URLs (e.g., https://i.pravatar.cc/300?img=1)

**15-20 Event records with FUTURE dates:**
- date_debut from tomorrow to +3 months (varied distribution)
- Varied tags: mix of "Contact Improvisation", "Danse des 5 Rythmes", "Authentic Movement", "Body-Mind Centering", "Danse Butô"
- Mix of type_event: atelier (60%) and stage (40%)
- Mix of gratuit: true (30%) and false (70%)
- Mix of en_ligne: true (20%), en_presentiel: true (80%)
- Realistic French titles (e.g., "Atelier Contact Improvisation", "Stage Danse des 5 Rythmes - Week-end intensif", "Exploration Authentic Movement")
- Varied prices: 0€ for gratuit events, 15-50€ for paid ateliers, 80-200€ for stages
- Different locations: Paris, Lyon, Marseille, Bordeaux, Toulouse, Nantes
- French descriptions (100-300 characters)
- All linked to professors via professor_id
- Some linked to scraped_urls (simulate scraped events), others with scraped_url_id null (simulate manual creation)
- Slugs auto-generated correctly (e.g., "atelier-contact-improvisation-paris-2026-03-26")

**5-6 Event records with PAST dates:**
- date_debut from -2 months to yesterday
- Same variety as future events (tags, types, prices, locations)
- Used to test Event.futurs scope and automatic hiding of past events

**And** all events have valid date_fin > date_debut
**And** duree_minutes is auto-calculated correctly via callback (e.g., 2h atelier = 120 minutes)
**And** running `Event.futurs.count` returns 15-20 (only future events)
**And** running `Event.count` returns 20-26 total (future + past)
**And** seed data is idempotent (running `rails db:seed` multiple times doesn't create duplicates - use `find_or_create_by!`)

---

### Story 1.3: Application Configuration (Environment, Jobs, Timezone)

As a developer,
I want application configuration for environment variables, Solid Queue, and timezone handling,
So that the app has correct timezone behavior and background jobs infrastructure.

**Acceptance Criteria:**

**Given** Rails 8 app with PostgreSQL configured locally
**When** I configure the application
**Then** the following configurations are in place:

**Environment Variables (dotenv-rails):**
- dotenv-rails gem installed and configured in Gemfile
- `.env.example` file exists at project root with:
```
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change_me_in_production
ALERT_EMAIL=admin@3graces.community
```
- `.env` file is in `.gitignore` (credentials never committed)
- README.md documents: "Copy `.env.example` to `.env` and set your production credentials before running the app"

**Solid Queue Configuration:**
- solid_queue gem installed in Gemfile
- `config/initializers/solid_queue.rb` exists with:
  - Queue names defined: :default, :scraping, :notifications
  - Job priorities: :default (0), :low (-10), :high (10)
  - Recurring tasks cron schedule placeholder (24h scraping - will be activated in Epic 3)
- ApplicationJob (`app/jobs/application_job.rb`) configured with retry strategy:
```ruby
class ApplicationJob < ActiveJob::Base
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  # Exponential backoff: 5s, 25s, 125s
end
```
- Development mode: inline job processing (jobs run immediately in-process for faster development)
- Production mode: worker processes configured (will be activated in Docker Compose Phase FIN)
- `rails solid_queue:start` command works for manual testing (starts workers in development)

**Timezone Configuration (CRITICAL - UTC storage, Europe/Paris display):**
- `config/initializers/timezone.rb` created with:
```ruby
Rails.application.configure do
  config.time_zone = "Europe/Paris"

  # IMPORTANT : garder :utc en base (défaut Rails).
  # Rails convertit automatiquement vers Europe/Paris à l'affichage
  # grâce à config.time_zone ci-dessus.
  # Stocker en local causerait des bugs aux changements d'heure été/hiver
  # (heure existe 2x en octobre, n'existe pas en mars).
  config.active_record.default_timezone = :utc
end
```
- All timestamp inputs in app use `Time.zone.parse()` for correct timezone handling
- Event model displays dates in Europe/Paris timezone automatically
- Logs configured for ISO 8601 format with timezone: `2026-03-25T19:30:00+01:00`

**And** running `rails console` and typing `Time.zone` returns `#<ActiveSupport::TimeZone:0x... @name="Europe/Paris">`
**And** creating test event: `Event.create!(titre: "Test", professor: Professor.first, date_debut: "2026-03-25 19:30", date_fin: "2026-03-25 21:30")` stores UTC in database column but displays "2026-03-25 19:30:00 +0100" in console
**And** `rails solid_queue:start` runs without errors (background jobs infrastructure ready)
**And** `.env` file exists locally with credentials set (copy from .env.example)

---

## PHASE FIN - Production Hardening (Stories 1.4-1.8)

*Ces stories s'exécutent APRÈS tous les autres epics pour finaliser le déploiement production.*

---

### Story 1.4: Docker Compose Production Environment

As a DevOps engineer,
I want a Docker Compose production configuration with Rails app, PostgreSQL, and Caddy,
So that the application can be deployed to production with automatic HTTPS.

**Acceptance Criteria:**

**Given** Rails 8.1.2 app developed and tested locally
**When** I create Docker Compose production configuration
**Then** the following files exist:

**Dockerfile (production-optimized):**
- Multi-stage build (builder stage + final stage)
- Base image: ruby:3.3 (or version from .ruby-version)
- Bundle install with --without development test
- Assets precompilation: `rails assets:precompile`
- Tailwind CSS build
- Exposes port 3000 (Puma)
- Entrypoint runs database migrations before starting server
- CMD: `bundle exec puma -C config/puma.rb`
- Solid Queue workers run in separate container (not in web container)

**docker-compose.yml (production):**
```yaml
services:
  db:
    image: postgres:16
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_USER: threegraces
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: threegraces_production
    restart: unless-stopped

  web:
    build: .
    depends_on:
      - db
    environment:
      RAILS_ENV: production
      DATABASE_URL: postgresql://threegraces:${DB_PASSWORD}@db/threegraces_production
      ADMIN_USERNAME: ${ADMIN_USERNAME}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      ALERT_EMAIL: ${ALERT_EMAIL}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
    volumes:
      - ./log:/app/log
      - ~/.claude:/root/.claude  # Claude CLI auth persistence
    ports:
      - "8080:3000"  # Avoid conflict with v1 (3000/3001), Nextcloud (80/443)
    restart: unless-stopped

  jobs:
    build: .
    depends_on:
      - db
    environment:
      RAILS_ENV: production
      DATABASE_URL: postgresql://threegraces:${DB_PASSWORD}@db/threegraces_production
    command: bundle exec rake solid_queue:start
    volumes:
      - ./log:/app/log
      - ~/.claude:/root/.claude  # Claude CLI needed for scraping jobs
    restart: unless-stopped

  caddy:
    image: caddy:2
    ports:
      - "8443:443"  # Temporary - see note below
      - "8000:80"   # Temporary - see note below
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - web
    restart: unless-stopped

volumes:
  postgres_data:
  caddy_data:
  caddy_config:
```

**⚠️ NOTE CADDY PORTS:** Caddy on ports 8443/8000 cannot obtain Let's Encrypt certificates (needs 80/443). **À résoudre lors de l'implémentation** — either Caddy replaces nginx as unique reverse proxy (Nextcloud + 3 Graces on same Caddy instance), or Caddy behind nginx. Decision deferred to implementation phase.

**Caddyfile (auto HTTPS via Let's Encrypt):**
```
3graces.community {
    reverse_proxy web:3000
    encode gzip
    log {
        output file /data/access.log
    }
}
```

**And** `.env.production.example` exists with all required variables (DB_PASSWORD, SECRET_KEY_BASE, etc.)
**And** README documents production deployment: `docker-compose up -d`
**And** Ports don't conflict with Docker v1 (3000/3001) or Nextcloud (80/443) - but HTTPS certificate issue to resolve
**And** Volume mount `~/.claude:/root/.claude` persists Claude CLI authentication
**And** Logs are accessible on host at `./log/production.log` and `./log/scraping.log`

---

### Story 1.5: Structured Logging & Log Rotation

As a system administrator,
I want structured logs with 90-day retention and rotation,
So that I can monitor the application and debug issues without filling disk space.

**Acceptance Criteria:**

**Given** Rails app running in production
**When** I configure logging
**Then** the following logging infrastructure is in place:

**Rails Logger Configuration (`config/environments/production.rb`):**
```ruby
config.log_level = :info
config.log_formatter = ::Logger::Formatter.new
config.logger = ActiveSupport::Logger.new(
  "log/production.log",
  10,           # Keep 10 old log files
  10.megabytes  # Rotate when file reaches 10MB
)
config.log_tags = [:request_id, :remote_ip]
```

**Scraping-specific logger (`config/initializers/scraping_logger.rb`):**
```ruby
SCRAPING_LOGGER = ActiveSupport::Logger.new(
  "log/scraping.log",
  10,
  10.megabytes
)
SCRAPING_LOGGER.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.iso8601}] #{severity} -- #{msg}\n"
end
```

**Structured logging in jobs/services:**
- All ScrapingJob, EventUpdateJob log with context hash:
```ruby
SCRAPING_LOGGER.info({
  scraped_url_id: scraped_url.id,
  url: scraped_url.url,
  duration_ms: duration,
  changes_detected: changes_count,
  status: 'success'
}.to_json)
```

**Log retention (cron job on host):**
- Script `scripts/cleanup_logs.sh` deletes logs older than 90 days:
```bash
#!/bin/bash
find ./log -name "*.log" -type f -mtime +90 -delete
```
- Cron: `0 2 * * * /home/dang/3graces-v2/scripts/cleanup_logs.sh`

**And** logs use ISO 8601 timestamps with timezone: `2026-03-25T19:30:00+01:00`
**And** scraping logs are separate from general Rails logs for easier monitoring
**And** log files auto-rotate when reaching 10MB
**And** old rotated logs are kept for 90 days then deleted

---

### Story 1.6: PostgreSQL Automated Backups

As a system administrator,
I want daily PostgreSQL backups with 30-day retention,
So that I can recover data in case of corruption or accidental deletion.

**Acceptance Criteria:**

**Given** PostgreSQL running in Docker production
**When** I configure automated backups
**Then** the following backup system is in place:

**Backup script (`scripts/backup_db.sh`):**
```bash
#!/bin/bash
BACKUP_DIR="/home/dang/3graces-v2/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/threegraces_${TIMESTAMP}.sql"

mkdir -p ${BACKUP_DIR}

docker exec threegraces_v2_db pg_dump \
  -U threegraces \
  threegraces_production \
  > ${BACKUP_FILE}

gzip ${BACKUP_FILE}

# Delete backups older than 30 days
find ${BACKUP_DIR} -name "*.sql.gz" -type f -mtime +30 -delete

echo "Backup completed: ${BACKUP_FILE}.gz"
```

**Cron job (daily at 3 AM):**
- Crontab entry: `0 3 * * * /home/dang/3graces-v2/scripts/backup_db.sh >> /home/dang/3graces-v2/log/backup.log 2>&1`

**Backup directory:**
- `/home/dang/3graces-v2/backups/` created
- `.gitignore` includes `backups/*.sql.gz`
- Permissions: `chmod 700 backups/` (only owner can read)

**And** backup script is executable: `chmod +x scripts/backup_db.sh`
**And** backups are compressed with gzip to save disk space
**And** old backups (>30 days) are automatically deleted
**And** backup logs written to `log/backup.log`
**And** README documents restore procedure: `docker exec -i threegraces_v2_db psql -U threegraces threegraces_production < backup.sql`

---

### Story 1.7: Email Alerting System for Critical Errors

As a system administrator,
I want email alerts sent within 15 minutes when scraping fails 3+ times consecutively,
So that I can respond quickly to critical issues.

**Acceptance Criteria:**

**Given** Solid Queue jobs running in production
**When** a ScrapedUrl fails 3 consecutive times
**Then** the alerting system triggers:

**AlertMailer (`app/mailers/alert_mailer.rb`):**
```ruby
class AlertMailer < ApplicationMailer
  default from: 'alerts@3graces.community'

  def critical_scraping_error(scraped_url)
    @scraped_url = scraped_url
    @recent_logs = scraped_url.change_logs.order(created_at: :desc).limit(5)

    mail(
      to: ENV['ALERT_EMAIL'],
      subject: "[3 Graces] CRITICAL: Scraping failed 3x for #{scraped_url.url}"
    )
  end
end
```

**AlertEmailJob (`app/jobs/alert_email_job.rb`):**
```ruby
class AlertEmailJob < ApplicationJob
  queue_as :notifications

  def perform(scraped_url_id)
    scraped_url = ScrapedUrl.find(scraped_url_id)
    AlertMailer.critical_scraping_error(scraped_url).deliver_now

    SCRAPING_LOGGER.warn({
      event: 'alert_sent',
      scraped_url_id: scraped_url_id,
      alert_email: ENV['ALERT_EMAIL']
    }.to_json)
  end
end
```

**Integration in ScrapingJob:**
- After 3rd consecutive failure, enqueue AlertEmailJob
- Logic: `if scraped_url.erreurs_consecutives >= 3`

**Email template (`app/views/alert_mailer/critical_scraping_error.html.erb`):**
- Subject: CRITICAL alert
- Body: URL, error count, recent error messages, timestamp
- Link to admin interface: `/admin/scraped_urls/#{scraped_url.id}`

**SMTP configuration (`config/environments/production.rb`):**
```ruby
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address: ENV['SMTP_ADDRESS'],
  port: 587,
  user_name: ENV['SMTP_USERNAME'],
  password: ENV['SMTP_PASSWORD'],
  authentication: 'plain',
  enable_starttls_auto: true
}
```

**And** alert is sent within 15 minutes of 3rd failure (meets NFR-R3)
**And** `.env.production.example` includes SMTP credentials placeholders
**And** alert email is readable (HTML formatted with error details)
**And** admin can click link in email to go directly to problematic URL in admin interface

---

### Story 1.8: Rate Limiting & Security Headers

As a security engineer,
I want rate limiting and security headers configured,
So that the application is protected from abuse and common web vulnerabilities.

**Acceptance Criteria:**

**Given** Rails app running in production with Caddy reverse proxy
**When** I configure security measures
**Then** the following protections are in place:

**Rate Limiting (Rack::Attack):**
- rack-attack gem installed
- `config/initializers/rack_attack.rb` configured:
```ruby
class Rack::Attack
  # Throttle general requests by IP (60 req/min)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle scraping admin actions (10 req/min)
  throttle('admin/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/admin')
  end

  # Blocklist malicious IPs (can be populated later)
  blocklist('bad-actors') do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 10.minutes) do
      req.path == '/admin' && req.post?
    end
  end
end
```

**Security Headers (`config/environments/production.rb`):**
```ruby
config.force_ssl = true  # Enforce HTTPS
config.ssl_options = { hsts: { expires: 1.year, subdomains: true } }

# Content Security Policy
config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https, :unsafe_inline  # Tailwind needs inline
end

# Prevent MIME sniffing
config.action_dispatch.default_headers['X-Content-Type-Options'] = 'nosniff'
# XSS protection
config.action_dispatch.default_headers['X-XSS-Protection'] = '1; mode=block'
# Prevent clickjacking
config.action_dispatch.default_headers['X-Frame-Options'] = 'SAMEORIGIN'
```

**Custom User-Agent for Scraping Bot:**
- In ScrapingEngine and all scrapers:
```ruby
USER_AGENT = "3graces.community bot - contact@3graces.community"
HTTParty.get(url, headers: { 'User-Agent' => USER_AGENT })
```

**robots.txt respecting (in scrapers):**
- Before scraping any URL, check robots.txt compliance (meets NFR-S1)
- Gem: `robots` or custom implementation

**RGPD Newsletter Consent:**
- Newsletter model already tracks `consenti_at` timestamp (Story 1.1)
- NewslettersController sets `consenti_at: Time.current` on create
- No email stored without explicit consent

**And** Rack::Attack logs throttled requests to `log/production.log`
**And** Rate limit: 60 requests/minute per IP for general traffic
**And** Rate limit: 10 requests/minute per IP for admin routes (more restrictive)
**And** Security headers visible in HTTP responses: `curl -I https://3graces.community | grep X-`
**And** HTTPS enforced (HTTP redirects to HTTPS automatically via Caddy + Rails force_ssl)
**And** Scraping bot identifies itself with custom user-agent in all HTTP requests

---

## Epic 1 Summary

**Total Stories:** 8 (3 Phase DÉBUT + 5 Phase FIN)

**Phase DÉBUT (Stories 1.1-1.3):** Executed at the beginning to enable UI development
**Phase FIN (Stories 1.4-1.8):** Executed after all other epics for production hardening

**All requirements covered:**
- FR51: Asset fingerprinting (Story 1.4 Dockerfile)
- NFR-T1-T11: Tech stack (Stories 1.1, 1.3, 1.4)
- NFR-R1-R4: Reliability (Stories 1.5, 1.6, 1.7)
- NFR-A1-A2: Availability (Stories 1.5, 1.7)
- NFR-O1-O3: Operational (Stories 1.3, 1.5, 1.6)
- ARCH-1-40: All infrastructure requirements (distributed across all 8 stories)
