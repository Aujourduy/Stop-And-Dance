---
stepsCompleted: [1, 2]
inputDocuments:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - docs/ui-reference.md
  - docs/brief.md
---

# 3graces-v2 - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for 3graces-v2, decomposing the requirements from the PRD, UX Design, and Architecture requirements into implementable stories.

## Requirements Inventory

### Functional Requirements

**FR1:** Display a chronological event agenda

**FR2:** Display event cards with: time · tags · title · presenter · location · price

**FR3:** Filter events by date

**FR4:** Filter events by type (atelier/stage)

**FR5:** Filter events by format (présentiel/en ligne)

**FR6:** Filter events by price (gratuit)

**FR7:** Implement basic keyword search in search bar (post-MVP with Algolia)

**FR8:** Implement geolocation search "Within X km of (city)" via Geocoding API (post-MVP)

**FR9:** Enable users to plan travel routes and organize "dance tours"

**FR10:** Track outbound clicks to professor websites

**FR11:** Email newsletter signup - simple registration form (MVP)

**FR12:** Newsletter subscription capability for user engagement

**FR13:** Automatic HTML scraping of predefined professor URLs via Solid Queue (cron + jobs)

**FR14:** Detect content changes via HTML diff with stored version

**FR15:** Automatic generation and update of event cards by Claude Code CLI headless

**FR16:** Write event data to PostgreSQL database

**FR17:** Maintain change detection journal/logs

**FR18:** Support light/dark theme toggle for users (POST-MVP)

**FR19:** Save user theme preference (light/dark mode) (POST-MVP)

**FR20:** Render responsive mobile-first interface

**FR21:** Support mobile layout: 375px - 768px with collapsible filter panel

**FR22:** Support tablet layout: 768px - 1024px

**FR23:** Support desktop layout: 1024px+ with permanent sidebar filters

**FR24:** Display sidebar filter panel visibly on desktop

**FR25:** Display full-width event list on mobile

**FR26:** Generate unique meta tags per page (title, description, canonical URL)

**FR27:** Generate Schema.org Event markup for each event (name, startDate, endDate, location, organizer, price)

**FR28:** Enable rich snippet display in Google Search

**FR29:** Generate Open Graph tags (og:title, og:description, og:image, og:url) for social sharing

**FR30:** Auto-generate XML sitemap for all events

**FR31:** Configure robots.txt for complete indexation

**FR32:** Generate semantic clean URLs (format: /evenements/event-name-city-date)

**FR33:** Automatically scrape professor website URLs (zero manual prof effort)

**FR34:** Generate public professor stats page accessible via unique URL: `/profs/prof-name/stats`

**FR35:** Display consultation count on professor stats page

**FR36:** Display outbound clicks on professor stats page

**FR37:** Provide public stats page with no account required

**FR38:** Allow light/dark theme toggle on professor stats page (POST-MVP)

**FR39:** Enable administrator manual addition of new URLs to scrape (rare)

**FR40:** Accept and read corrective notes per URL (text files per URL)

**FR41:** Claude Code CLI reads corrective notes before parsing each URL

**FR42:** Display clear logs of scraping activity

**FR43:** Display parsing logs

**FR44:** Display error logs

**FR45:** Provide manifest.json for PWA with app name, icons, colors (POST-MVP)

**FR46:** Provide Service Worker for PWA (POST-MVP)

**FR47:** Enable installation on mobile home screen (iOS and Android) (POST-MVP)

**FR48:** Implement network-first caching strategy for HTML/JSON content (POST-MVP)

**FR49:** Auto-update Service Worker with version detection (POST-MVP)

**FR50:** Display prompt to user for app refresh when new version available (POST-MVP)

**FR51:** Generate automatic cache-busting with asset fingerprinting

### Non-Functional Requirements

#### Performance (P)

**NFR-P1:** First Contentful Paint (FCP) < 1.5 seconds

**NFR-P2:** Time to Interactive (TTI) < 3 seconds

**NFR-P3:** Largest Contentful Paint (LCP) < 2.5 seconds

**NFR-P4:** Optimize images in WebP format with lazy loading

**NFR-P5:** Minify CSS/JS via Rails asset pipeline

**NFR-P6:** Enable instant navigation without full page reload via Turbo

#### Security (S)

**NFR-S1:** No data leakage from scraping operations (secure handling of external URLs)

**NFR-S2:** Protect user email addresses in newsletter subscription

#### Reliability (R)

**NFR-R1:** System must operate autonomously for 7 consecutive days without manual intervention

**NFR-R2:** Achieve 95%+ accuracy in generated event cards (correct dates, locations, prices)

**NFR-R3:** Detection of all HTML changes without silent errors (no undetected changes or failed parsing)

**NFR-R4:** Scraping system must be robust and handle parsing failures gracefully

#### Availability (A)

**NFR-A1:** System must maintain production uptime for continuous event availability

**NFR-A2:** Journal of changes must clearly log all detected issues

#### Compatibility (C)

**NFR-C1:** Support Chrome/Edge - 2 latest versions

**NFR-C2:** Support Firefox - 2 latest versions

**NFR-C3:** Support Safari - 2 latest versions (iOS and macOS)

**NFR-C4:** Do not support Internet Explorer 11 and obsolete browsers

#### Accessibility (AC)

**NFR-AC1:** Conform to WCAG 2.1 AA standard (legal compliance France/EU)

**NFR-AC2:** Maintain minimum color contrast 4.5:1 for normal text

**NFR-AC3:** Maintain minimum color contrast 3:1 for large text

**NFR-AC4:** Support full keyboard navigation (Tab, Enter, Esc)

**NFR-AC5:** Include ARIA labels on interactive elements (filters, buttons)

**NFR-AC6:** Provide descriptive alt text on all images

**NFR-AC7:** Use semantic HTML5 structure (header, nav, main, article, footer)

**NFR-AC8:** Display visible focus indicators on interactive elements

**NFR-AC9:** Achieve Lighthouse Accessibility score > 90

**NFR-AC10:** Pass validation with screen readers (NVDA or VoiceOver)

#### Scalability (SC)

**NFR-SC1:** Architecture must support adding new professor URLs without system redesign

**NFR-SC2:** System must handle growing event database without performance degradation

#### Technology Stack (T)

**NFR-T1:** Use Rails 8 framework

**NFR-T2:** Use PostgreSQL database

**NFR-T3:** Use Solid Queue for cron + job orchestration

**NFR-T4:** Use Claude Code CLI headless (Pro subscription, not Claude API)

**NFR-T5:** Use Tailwind CSS for styling

**NFR-T6:** Use Docker on HP EliteDesk Linux server (headless)

**NFR-T7:** Use Turbo for SPA-style navigation

**NFR-T8:** Use Algolia for keyword search (post-MVP)

**NFR-T9:** Use Algolia Geo Search or Google Maps for geolocation API

**NFR-T10:** Use Cloudinary for optimized professor avatars and event images (post-MVP)

**NFR-T11:** Use Multi-Page App (MPA) architecture with Rails 8 + Turbo + Tailwind CSS

#### Operational (O)

**NFR-O1:** System designed to operate with minimal human intervention

**NFR-O2:** Support file-based corrective notes system for URL configuration (no complex admin interface)

**NFR-O3:** Clear, simple logs for monitoring (no complex dashboard required)

### Additional Requirements (from Architecture)

**ARCH-1:** Rails 8.1.2 project already exists at /home/dang/stop-and-dance (no starter template needed)

**ARCH-2:** PostgreSQL with timezone forced to Europe/Paris display, UTC storage (config.active_record.default_timezone = :utc)

**ARCH-3:** Docker Compose with 3 containers: Rails app (Puma), PostgreSQL, Caddy reverse proxy

**ARCH-4:** Caddy reverse proxy for automatic HTTPS/TLS 1.3 via Let's Encrypt (not nginx)

**ARCH-5:** Volume mounts: ~/.claude:/root/.claude (Claude CLI auth), ./db:/var/lib/postgresql/data (PostgreSQL), ./log:/app/log (logs)

**ARCH-6:** Database migrations for 7 core models: Professor, ScrapedUrl, ProfessorScrapedUrl (join table), Event, EventSource (multi-source tracking), ChangeLog, Newsletter

**ARCH-7:** Professor model with avatar_url (external URL), bio, site_web, email, consultations_count, clics_sortants_count

**ARCH-8:** Event model with nullable scraped_url_id (allows manual creation), date_debut/date_fin (UTC stored, Paris display), duree_minutes (auto-calculated via callback), type_event enum, gratuit/en_ligne/en_presentiel booleans

**ARCH-9:** EventSource join table for multi-source event tracking with primary_source flag and unique index [:event_id, :scraped_url_id]

**ARCH-10:** ProfessorScrapedUrl join model (has_many :through pattern, not HABTM) for extensibility

**ARCH-11:** Indexes on events.date_debut, events.gratuit, events.type_event

**ARCH-12:** Seed file db/seeds.rb with demo data (Professor, ScrapedUrl, Event samples)

**ARCH-13:** Admin credentials via .env (ADMIN_USERNAME, ADMIN_PASSWORD) for HTTP Basic Auth

**ARCH-14:** Claude Code CLI headless integration with --dangerously-skip-permissions flag, shell exec from lib/claude_cli_integration.rb

**ARCH-15:** Solid Queue configuration with cron schedule (24h), exponential backoff retry (max 3x), queue names (:default, :scraping, :notifications)

**ARCH-16:** 4 specialized scrapers: HtmlScraper (generic), GoogleCalendarScraper, HelloassoScraper, BilletwebScraper with URL pattern detection

**ARCH-17:** HtmlDiffer service (lib/html_differ.rb) for change detection with changements_detectes jsonb output

**ARCH-18:** Error handling: erreurs_consecutives counter, alert trigger after 3 failures, email to admin < 15min

**ARCH-19:** Logging infrastructure: structured logs with context hash, 90-day retention, log files (development.log, production.log, scraping.log)

**ARCH-20:** Alert system via AlertMailerService + AlertMailer + AlertEmailJob with admin email from .env (ALERT_EMAIL)

**ARCH-21:** HTTP Basic Auth for admin routes via Admin::ApplicationController (Rails native http_basic_authenticate_with)

**ARCH-22:** Admin controllers: Admin::ScrapedUrlsController (CRUD + scrape_now/preview), Admin::ChangeLogsController (view only), Admin::EventsController (view + edit)

**ARCH-23:** Admin routes: /admin/scraped_urls, /admin/scraped_urls/:id/scrape_now (POST), /admin/scraped_urls/:id/preview (GET dry-run), /admin/change_logs, /admin/events

**ARCH-24:** Public routes in French: /evenements, /evenements/:slug, /professeurs/:id, /professeurs/:id/stats

**ARCH-25:** Asset pipeline: Propshaft (Rails 8), Tailwind CSS JIT via tailwindcss-rails, Import maps (no bundler), minification + fingerprinting

**ARCH-26:** Testing: Minitest, test structure (models, controllers, jobs, integration), fixtures YAML, mocks (JSON/HTML samples in test/mocks/)

**ARCH-27:** Timezone handling: Input via Time.zone.parse(), output "25 mars 2026, 19h30" (French 24h), logs ISO 8601 with timezone

**ARCH-28:** Localization: French only, config/locales/fr.yml, French flash messages

**ARCH-29:** Naming conventions: Tables snake_case plural, columns snake_case, FKs singular_id, classes PascalCase singular, jobs JobSuffix

**ARCH-30:** Performance implementation: WebP + lazy loading, fragment caching Rails (invalidate post-scraping), Turbo navigation, in-memory cache (no Redis MVP)

**ARCH-31:** Required gems: pg, solid_queue, puma, tailwindcss-rails, pagy, rack-attack, httparty, dotenv-rails

**ARCH-32:** Database backup: Daily pg_dump via cron, 30-day retention, script with docker exec

**ARCH-33:** Atomic SQL counters: Professor.increment_counter(:consultations_count, id) for race-condition-free updates

**ARCH-34:** Rate limiting: Rack::Attack config (60 req/min per IP), custom user-agent for scraping bot

**ARCH-35:** Security headers: HTTPS TLS 1.3, CSRF protection, CSP, Rails default security headers

**ARCH-36:** RGPD: Newsletter.consenti_at timestamp, data minimization (no personal data except newsletter consent)

**ARCH-37:** Infinite scroll: Turbo Frames lazy loading, 30 events/batch, pagy gem server-side, no pagination numbers

**ARCH-38:** PagesController for static pages (home, about, contact) with views/pages/ and partials (_hero, _navbar, _mobile_drawer)

**ARCH-39:** Stimulus controllers: filters_controller.js, mobile_drawer_controller.js, carousel_controller.js

**ARCH-40:** Navigation: _navbar.html.erb (desktop), _mobile_drawer.html.erb (mobile overlay)

### UX Design Requirements

**UX-DR1:** Define and implement terracotta/orangé primary color (#C2623F or similar) as custom design token in Tailwind config for consistent use across CTA buttons, headers, and accent elements

**UX-DR2:** Define and implement beige/crème secondary color as custom design token in Tailwind config for background elements and alternative styling

**UX-DR3:** Define dark background design token (near-black) for overall page backgrounds and contrast with light text

**UX-DR4:** Implement script/italic elegant typography for primary titles (such as "AU JOUR duy" logo and page headers) with custom font-family configuration

**UX-DR5:** Implement sans-serif body text typography for readability with custom font-family configuration in Tailwind

**UX-DR6:** Create reusable pill/tag component with rounded-full styling, customizable background colors for event types (Atelier: terracotta, Stage: light terracotta, Gratuit: soft green, En ligne: blue/teal, En présentiel: neutral)

**UX-DR7:** Build Hero section component for homepage with full-width dancer photo background, white script logo overlay, white italic text presentation, and responsive 2x3 grid of CTA buttons (AGENDA, PUBLIER ATELIERS, ACTUALITÉS, QUI EST DUY, ME CONTACTER, DONATIONS)

**UX-DR8:** Implement responsive navigation header with small logo (top left), hamburger menu icon, calendar icon, and newsletter icon (top right) with dropdown menu containing: Accueil, Agenda, S'inscrire à la newsletter, Liens, L'espace des proposants

**UX-DR9:** Create two-column event list layout for desktop with main column (70% width) showing chronological events and right sidebar (30% width) for search, filters, and newsletter signup

**UX-DR10:** Implement mobile-first event list with full-width layout and collapsible "Filtrez l'agenda" button that triggers overlay filter panel

**UX-DR11:** Build date separator component for event list displaying format "Samedi 18/11/2023" in italic gray/dark text with fine dividing line

**UX-DR12:** Create event card component with flex layout containing: 80x80 square photo (left), terracotta bold time (10h15), event tags, bold title, gray "Animé par" text, location pin icon with city, and price display

**UX-DR13:** Build event detail modal with close button (top right), event tags row, photo carousel with right arrow navigation visible, italic title, and structured info block (presenter, start/end datetime, duration, location with address, normal/reduced pricing, external links)

**UX-DR14:** Implement "Description" section header in terracotta bold with scrollable text content in event detail modal

**UX-DR15:** Create sidebar filter panel (desktop: permanent sticky right sidebar; mobile: fixed overlay) with header "Filtrez l'agenda" in italic on terracotta background and close button on mobile

**UX-DR16:** Implement filter checkboxes in 2-column grid: EN PRÉSENTIEL, STAGE, EN LIGNE, GRATUIT, ATELIER with checked state indicators

**UX-DR17:** Add date range filter with "À PARTIR DU" label and JJ/MM/AAAA date input field

**UX-DR18:** Add geographic filter section with "LIEU" text input (Adresse, ville...) and "DISTANCE" numeric input (km) fields

**UX-DR19:** Build "APPLIQUER" button for filters with terracotta background, full width in filter panel, applying selected criteria to event list

**UX-DR20:** Create search component block with terracotta dark background, "Recherchez" label in italic, text input field, magnifying glass icon, and placeholder text "Saisir votre recherche directement"

**UX-DR21:** Build newsletter signup component block with terracotta background, "S'inscrire à la newsletter" label in italic, email input field, and "SOUSCRIRE" button in terracotta

**UX-DR22:** Implement responsive breakpoint for iPhone 12 Pro (390 × 844px) mobile reference with mobile-first design strategy

**UX-DR23:** Implement responsive breakpoint for MacBook Pro 16" desktop (1728px width) with sidebar permanently visible

**UX-DR24:** Create dark mode toggle switch that persists user preference to localStorage and applies dark: variants across all components (POST-MVP)

**UX-DR25:** Implement PWA installability with add-to-homescreen capability for mobile devices (POST-MVP)

**UX-DR26:** Configure PWA network-first caching strategy (no offline fallback cache) (POST-MVP)

**UX-DR27:** Implement in-app notification system for PWA new version availability alerts (POST-MVP)

**UX-DR28:** Configure Tailwind custom color extension for terracotta primary in tailwind.config.js using @apply or custom theme configuration

**UX-DR29:** Implement event card flex layout with consistent gap and padding using Tailwind utilities (flex, gap-*, p-*)

**UX-DR30:** Ensure tag pills styling uses rounded-full, px-3, py-1, text-sm Tailwind classes for consistent appearance

**UX-DR31:** Implement sidebar/filter panel with sticky positioning (sticky top-0) on desktop and hidden state on mobile using Tailwind responsive classes

**UX-DR32:** Create filter panel overlay animation using slide-in effect or fixed inset-0 positioning for mobile transitions

### FR Coverage Map

**Epic 1 (Infrastructure & Deployment):** Database setup, Docker, Caddy, backups, monitoring, security, seed data with 15-20 realistic events
**Epic 2 (Homepage & Design System):** FR20-FR25, Design tokens, hero, navigation, responsive layouts, WCAG 2.1 AA
**Epic 3 (Automated Scraping Engine):** FR13-FR17, FR39-FR44, scrapers, Claude CLI, rake tasks, error handling, alerting
**Epic 4 (Event Discovery & Browsing):** FR1, FR2, FR9 (chronological agenda, event cards, detail modal, infinite scroll)
**Epic 5 (Event Filtering):** FR3-FR6 (filters date/type/format/gratuit), FR7-FR8 post-MVP (search/geocoding)
**Epic 6 (Newsletter):** FR11, FR12 (subscription, RGPD consent)
**Epic 7 (Professor Profiles & Stats):** FR10, FR33-FR37 (stats pages, atomic counters, click tracking)
**Epic 8 (SEO & Discoverability):** FR26-FR32, FR51 (meta tags, Schema.org, sitemap, Open Graph, performance optimization)
**Epic 9 (Admin Interface):** FR39-FR44 (web interface over scraping engine, CRUD URLs, view logs, correct events)

**POST-MVP (exclus):**
- FR7, FR8 (Algolia search/geocoding)
- FR18, FR19, FR38 (dark mode)
- FR45-FR50 (PWA)

## Epic List

### Epic 1: Infrastructure & Deployment
Enable the development team to build on a production-ready foundation and deploy to production with full monitoring.

**User Outcome:** Complete development environment + production deployment pipeline with database, jobs orchestration, monitoring, backups, and security.

**FRs covered:** FR51, NFR-T1 à T11, NFR-R1 à R4, NFR-A1 à A2, NFR-O1 à O3, ARCH-1 à ARCH-6, ARCH-11 à ARCH-13, ARCH-15, ARCH-19, ARCH-20, ARCH-25 à ARCH-32, ARCH-34 à ARCH-36

**Implementation Notes:**
**PHASE DÉBUT (Stories 1.1-1.5) - Enable UI Development:**
- Rails 8.1.2 already exists - configure existing project
- Database migrations (7 models: Professor, ScrapedUrl, ProfessorScrapedUrl, Event, EventSource, ChangeLog, Newsletter)
- **Seed data with 15-20 realistic demo events** (3-4 professors, future dates, varied tags: atelier/stage, gratuit, en ligne/présentiel) - enables parallel UI development without waiting for scraping
- Admin credentials (.env)
- Solid Queue setup (cron + jobs)
- Docker Compose dev environment (Rails + PostgreSQL)

**PHASE FIN (Stories 1.6-1.10) - Production Hardening (after all other epics):**
- Docker Compose production config
- Caddy reverse proxy (HTTPS TLS 1.3 auto Let's Encrypt)
- Logging infrastructure (structured logs, 90d retention, scraping.log)
- Alert system (email after 3 failures < 15min)
- PostgreSQL backups (daily pg_dump, 30d retention)
- Rate limiting (Rack::Attack 60 req/min)
- Security headers (CSRF, CSP, TLS 1.3)
- RGPD compliance (Newsletter consent tracking)


### Epic 2: Homepage & Design System
Enable users to experience a beautiful, branded, accessible homepage with full navigation on any device.

**User Outcome:** Users land on an inspiring terracotta/beige themed homepage with hero section, navigation, and complete design system for all future components.

**FRs covered:** FR20-FR25, NFR-AC1 à AC10, NFR-C1 à C4, UX-DR1 à UX-DR32, ARCH-38 à ARCH-40

**Implementation Notes:**
- Tailwind config (terracotta #C2623F, beige, dark background, typography tokens)
- Responsive breakpoints (mobile 390px iPhone 12 Pro, desktop 1728px MacBook Pro 16")
- Reusable components: pill/tag component (event types with color coding)
- PagesController (home, about, contact)
- Hero section component (full-width dancer photo + white script logo + 2x3 CTA grid)
- Navigation (desktop navbar + mobile hamburger drawer with Stimulus)
- Stimulus controllers (carousel_controller.js, mobile_drawer_controller.js)
- WCAG 2.1 AA compliance (contrast 4.5:1, keyboard nav, ARIA, semantic HTML5)
- Lighthouse Accessibility > 90
- Mobile-first layout patterns (full-width mobile, two-column desktop)


### Epic 3: Automated Scraping Engine
Enable the system to automatically discover and update event information from professor websites without manual intervention.

**User Outcome:** Events are automatically scraped from professor websites every 24h, changes detected, and event data updated via Claude CLI with zero manual work.

**FRs covered:** FR13-FR17, FR39-FR44, NFR-R1 à R4, ARCH-14, ARCH-16 à ARCH-20

**Implementation Notes:**
- ScrapingEngine service (lib/scraping_engine.rb) with URL pattern detection
- 4 specialized scrapers: HtmlScraper (generic), GoogleCalendarScraper, HelloassoScraper, BilletwebScraper
- HtmlDiffer service (lib/html_differ.rb) for change detection with changements_detectes jsonb
- Claude CLI headless integration (lib/claude_cli_integration.rb) with --dangerously-skip-permissions flag
- ScrapingJob + EventUpdateJob (Solid Queue)
- Cron schedule (24h via Solid Queue recurring_tasks)
- Retry strategy (exponential backoff, max 3 attempts)
- ChangeLog model (stores diff_html + timestamp)
- Error handling: erreurs_consecutives counter on ScrapedUrl
- Alert trigger after 3 consecutive failures → AlertEmailJob → AlertMailer (< 15min)
- **Rake tasks for manual control:**
  - `rake scraping:run_all` - Trigger scraping for all active URLs
  - `rake scraping:run[scraped_url_id]` - Trigger scraping for specific URL
  - `rake scraping:test[scraped_url_id]` - Dry-run test without DB write
- Notes correctrices per URL (ScrapedUrl.notes_correctrices text field, read by Claude CLI)


### Epic 4: Event Discovery & Browsing
Enable users to browse all dance events chronologically and see full event details.

**User Outcome:** Users see the complete agenda of scraped dance events, browse chronologically with infinite scroll, and click any event to see detailed information in a modal.

**FRs covered:** FR1, FR2, FR9, UX-DR9 à UX-DR14, ARCH-37

**Implementation Notes:**
- EventsController (index, show)
- Event index view with two-column layout (70% events, 30% sidebar on desktop; full-width on mobile)
- Date separator component ("Samedi 18/11/2023" in italic gray)
- Event card component (80x80 photo, terracotta time, tags, title, "Animé par", location icon, price)
- Event detail modal (close button, tags row, photo carousel with arrow nav, presenter info, datetime/duration, location, pricing, external links)
- Description section (terracotta bold header, scrollable text)
- Infinite scroll via Turbo Frames (30 events/batch, pagy gem server-side pagination)
- Responsive: desktop two-column, mobile full-width stack
- Uses seed data from Epic 1 for development


### Epic 5: Event Filtering & Search
Enable users to filter events by multiple criteria to find exactly what they're looking for.

**User Outcome:** Users can filter events by date, type, format, price to narrow down the agenda and plan their dance activities.

**FRs covered:** FR3-FR6, (FR7-FR8 post-MVP), UX-DR15 à UX-DR19

**Implementation Notes:**
- Filter panel component (desktop: permanent sticky sidebar 30% width, mobile: fixed overlay with slide-in animation)
- Filter header "Filtrez l'agenda" in italic on terracotta background
- Filter checkboxes (2-column grid): EN PRÉSENTIEL, STAGE, EN LIGNE, GRATUIT, ATELIER
- Date range filter: "À PARTIR DU" with JJ/MM/AAAA input
- Geographic filter (LIEU text input + DISTANCE km) - **basic version MVP, full geocoding post-MVP**
- "APPLIQUER" button (terracotta, full-width)
- Stimulus filters_controller.js (manages filter state + Turbo Frame requests)
- Mobile: collapsible "Filtrez l'agenda" button triggers overlay
- Close button on mobile overlay
- **POST-MVP:** FR7 keyword search (Algolia), FR8 geocoding (Algolia Geo Search or Google Maps API)


### Epic 6: Newsletter Subscription
Enable users to subscribe to email updates about new events.

**User Outcome:** Users can sign up for the newsletter from the sidebar or footer and receive event updates.

**FRs covered:** FR11, FR12, NFR-S2, ARCH-6 (Newsletter model), UX-DR21

**Implementation Notes:**
- Newsletter model + migration (email unique, consenti_at timestamp, actif boolean)
- NewslettersController (create action only)
- Newsletter signup component (terracotta background, "S'inscrire à la newsletter" italic label, email input, "SOUSCRIRE" button)
- Component appears in: event list sidebar (desktop), footer (all pages)
- Email validation + uniqueness
- RGPD: consenti_at timestamp tracks consent date
- Simple success/error flash messages
- **POST-MVP:** Actual newsletter sending (ActionMailer + scheduled job)


### Epic 7: Professor Profiles & Stats
Enable users to discover professors and view their public engagement statistics.

**User Outcome:** Users can click on a professor to see their bio, workshops, and public stats (page views + outbound clicks to their website).

**FRs covered:** FR10, FR33-FR37, ARCH-7, ARCH-33

**Implementation Notes:**
- ProfessorsController (show, stats)
- Professor show page (avatar, bio, site_web, email, upcoming events)
- Professor stats page at `/professeurs/:id/stats` (public, no auth)
- Tracking counters: consultations_count (professor page views), clics_sortants_count (clicks to professor website)
- **Atomic SQL counters:** Professor.increment_counter(:consultations_count, id) for race-condition-free updates
- Tracking implementation:
  - Consultations: increment on ProfessorsController#show
  - Clics sortants: Route intermédiaire `/professeurs/:id/redirect_to_site` (increment + redirect)
- Stats display: simple counter cards (consultations, clics sortants)


### Epic 8: SEO & Discoverability
Enable search engines to index all events and users to share events beautifully on social media.

**User Outcome:** Events appear in Google Search with rich snippets, site is fully indexed, and events look great when shared on Facebook/Twitter.

**FRs covered:** FR26-FR32, FR51, NFR-P1 à P6

**Implementation Notes:**
- SEO concern (app/controllers/concerns/seo_metadata.rb) mixed into controllers
- Meta tags per page (title, description, canonical URL)
- Schema.org Event markup (JSON-LD: name, startDate, endDate, location, organizer, offers with price)
- Open Graph tags (og:title, og:description, og:image, og:url, og:type)
- SitemapsController generates XML sitemap (/sitemap.xml) with all events
- robots.txt config (Allow: /, Sitemap: https://3graces.community/sitemap.xml)
- Semantic URLs: /evenements/:slug (slug = "event-name-city-date")
- Performance optimization:
  - Images: WebP format + lazy loading (loading="lazy")
  - CSS/JS minification via Propshaft
  - Turbo navigation (instant page loads without full reload)
  - Fragment caching for event list (invalidate post-scraping)
- Cache-busting: Asset fingerprinting via Propshaft


### Epic 9: Admin Interface
Enable administrators to manage scraping URLs, view logs, and correct event data via web interface.

**User Outcome:** Admins can add/edit scraping URLs, trigger manual scraping, view change logs, and correct parsing errors through a simple admin dashboard.

**FRs covered:** FR39-FR44, ARCH-21 à ARCH-23

**Implementation Notes:**
- HTTP Basic Auth via Admin::ApplicationController (credentials from .env: ADMIN_USERNAME, ADMIN_PASSWORD)
- Admin namespace: `/admin/*` routes
- **Admin::ScrapedUrlsController** (CRUD + special actions):
  - Index: list all URLs with status (actif, erreurs_consecutives)
  - Show: URL details + recent ChangeLogs
  - New/Create: add new scraping URL
  - Edit/Update: modify URL or notes_correctrices
  - `scrape_now` (POST): trigger ScrapingJob.perform_later for this URL immediately
  - `preview` (GET): dry-run test (calls scraper without DB write, shows parsed output)
- **Admin::ChangeLogsController** (read-only):
  - Index: list all changes with filters (URL, date range)
  - Show: detailed diff_html + changements_detectes jsonb
- **Admin::EventsController** (view + edit for corrections):
  - Index: list events with filters
  - Show: event details
  - Edit/Update: correct parsing errors manually
- Minimal design: semantic HTML + Tailwind utility classes, tables for lists, standard Rails form helpers
- Pagination with pagy gem
- Flash messages for feedback
- **Note:** Rake tasks (scraping:run_all, scraping:test) are part of Epic 3 Scraping Engine. Admin interface provides web-based access to same functionality.


---

## Post-MVP Features

### Analytics
- **Cloudflare Analytics** : Activer dans le dashboard Cloudflare (trafic, bande passante, menaces)
- **Plausible Analytics** : Installer pour analytics privacy-friendly (alternative à Google Analytics)
  - Script léger (~1KB)
  - Pas de cookies
  - RGPD compliant par défaut
  - Dashboard stats visiteurs, pages vues, sources

### Search & Discovery
- **FR7:** Keyword search avec Algolia (barre de recherche)
- **FR8:** Geocoding API pour "Dans X km de (ville)"
- **NFR-T8:** Algolia search index configuration

### Media & Assets
- **NFR-T10:** Cloudinary pour avatars professeurs et images événements optimisées

### PWA (Progressive Web App)
- **FR45:** manifest.json (nom app, icônes, couleurs)
- **FR46:** Service Worker pour offline
- **FR47:** Installation sur écran d'accueil mobile (iOS/Android)
- **FR48:** Network-first caching strategy
- **FR49:** Auto-update Service Worker avec détection version
- **FR50:** Prompt utilisateur pour refresh quand nouvelle version

### Theme
- **FR18:** Toggle light/dark mode
- **FR19:** Persistence préférence thème utilisateur

### Newsletter
- Envoi effectif newsletter (ActionMailer + job planifié)
- Gestion désabonnement
- Templates emails événements
