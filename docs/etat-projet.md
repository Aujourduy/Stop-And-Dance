# État du Projet - Stop & Dance

**Dernière mise à jour :** 2026-04-09
**Branch :** main
**Dernier commit main :** 7d6376b
**Statut :** ✅ **PROJET COMPLET** + DaisyUI + Crawler + Récurrences + Date/heure + Notifications + Photos locales + Jobs admin

---

## 📋 Synthèse Globale

**Stop & Dance** est un agenda d'événements de danse exploratoire en France. Site public read-only avec système de scraping automatisé alimenté par Claude AI.

**Stack technique :** Rails 8.1.2, PostgreSQL, Solid Queue, Tailwind CSS v4, Turbo, Pagy, Playwright

**Environnement :**
- Dev : port 3002 (Rails local)
- Prod : port 3000 (Docker + Caddy)
- Admin : HTTP Basic Auth (restreint VPN Tailscale optionnel)
- Domaine : stopand.dance (HTTPS via Cloudflare)

**Qualité :**
- 89 tests unitaires (0 failures)
- CI GitHub Actions : lint + tests + security scan
- RuboCop : 0 offenses
- Brakeman : 0 warnings (Ruby EOL ignoré, upgrade Ruby 3.4 planifié)

---

## 🎯 Fonctionnalités Principales

### Site Public

**Homepage & Navigation**
- Hero responsive avec titre animé
- Navigation desktop/mobile avec burger menu
- Lien Admin dans menu burger mobile
- Design system terracotta/beige (Tailwind CSS v4)
- Accessibilité WCAG 2.1 AA
- Mode debug design (Ctrl+Shift+D)

**Liste Événements**
- Affichage chronologique (futurs uniquement)
- Infinite scroll avec Pagy
- Cartes événements : avatar prof 128×128px + 4 lignes info
- Cartes pleine largeur sur mobile (bord à bord)
- Compteurs dynamiques dans le titre (ateliers/stages)
- Modal détails événement (Turbo Frame)
- Jours en français capitalisés (Dimanche 5 Avril 2026)
- Vignettes : "Atelier" (pas Workshop), "Présentiel" (pas En présentiel)
- Prix réduit compact : 20,00€/16,00€

**Filtres Multi-Critères**
- **Recherche full-text** : champ texte multi-mots (opérateur AND), cherche dans titre, description, lieu, adresse, tags, nom professeur
- Date (date picker)
- Type (atelier/stage)
- Format (en ligne/présentiel)
- Prix (gratuit/payant)
- Lieu (texte)
- Reset filtres
- Auto-submit en temps réel (debounce 400ms pour recherche texte)
- Panneau mobile slide depuis droite

**Profils Professeurs**
- Page profil : bio, photo, site web
- Liste événements du professeur
- Stats publiques : vues + clics sortants
- Redirect tracking vers site externe

**Newsletter**
- Formulaire sidebar + footer
- Validation email
- Flash messages succès/erreur
- Admin : consultation liste emails

**SEO**
- Meta tags dynamiques (Open Graph, Twitter Cards)
- JSON-LD structured data (Event, Person)
- Sitemap.xml auto-généré (cache 1h)
- robots.txt

### Système de Scraping Automatisé

**Scrapers**
- **HtmlScraper (HTTParty)** : sites statiques, rapide (1-2s)
- **PlaywrightScraper (Chromium)** : sites JavaScript (Wix, React, Vue), timeout 10min
- User-Agent : "stopand.dance bot - contact@stopand.dance"
- Choix du scraper via `use_browser` (true = Playwright, false = HTTParty)

**Pipeline de Scraping**
1. **ScrapingDispatchJob** : lance scraping toutes les 24h (Solid Queue)
2. **ScrapingJob** : scraping par URL (retry 3x exponentiel)
3. **ScrapingEngine** :
   - Télécharge HTML (HTTParty ou Playwright selon `use_browser`)
   - Calcule html_hash (SHA256) pour détection changements O(1)
   - Compare avec version précédente (HtmlDiffer)
   - Si changements → enqueue EventUpdateJob
4. **EventUpdateJob** :
   - Convertit HTML → Markdown + data-attributes (HtmlCleaner)
   - Réduction tokens : 98.7% (419 KB → 5 KB exemple Wix)
   - Parse avec Claude CLI (ClaudeCliIntegration)
   - Crée/update Events en base
   - Déduplication professeurs par nom_normalise

**Détection Changements**
- HtmlDiffer : compare HTML versions (lignes ajoutées/supprimées)
- ChangeLog : stocke diff + métadonnées
- Admin : consultation historique changements

**Parsing Claude CLI**
- Prompt : Markdown + data-attributes + consignes globales + notes correctrices
- Output : JSON array événements structurés
- Timeout : 120s
- Mode headless : --dangerously-skip-permissions

**Déduplication Professeurs**
- Migration : champ prenom + nom_normalise (prenom + nom, unique index) + status (auto/reviewed)
- Normalisation : strip, downcase, unaccent, 1 space
- Auto-création : Claude extrait professor_nom par event → find_or_create avec status="auto"
- Recherche 3 niveaux : ScrapedUrl.professors → global → create new
- Admin review : alerte dashboard + /admin/professors pour vérifier/compléter + bouton "Marquer vérifié"
- Seeds : 5 profs dont 2 multi-sources (Sophie, Marie au Studio Collectif)

### Interface Admin

**Dashboard** (`/admin`)
- HTTP Basic Auth (credentials ENV : ADMIN_USERNAME, ADMIN_PASSWORD)
- Accès restreint VPN Tailscale (optionnel)

**CRUD ScrapedUrls**
- Liste avec badges mode (HTTParty/Playwright)
- Formulaire edit : choix visuel HTTParty vs Playwright
- Champs : url, nom, commentaire, notes_correctrices, statut_scraping, use_browser

**Test Scraping** (4 boutons dans preview)
- 🌐 **HTTParty** : test fetch rapide sans JS (1-2s)
- 🎭 **Playwright** : test browser complet avec JS (10min max)
- 📝 **Markdown maker** : conversion HTML→Markdown instantanée
- 🔄 **Re-parser avec Claude** : parsing Markdown→Events (30-60s)
- Infobulles détaillées sur chaque bouton

**Preview Scraping** (6 onglets)
- Résultat parsing : events JSON (cache DB)
- Markdown view : rendu HTML stylé (redcarpet)
- Markdown brut : code source
- Data attributes : data-* extraits du HTML
- HTML view : rendu dans iframe sandbox
- HTML brut : code source HTML
- Performance : prévisualisation instantanée (cache DB)

**CRUD Professeurs** (`/admin/professors`)
- Liste avec filtres : Tous / À vérifier (auto)
- Alerte dashboard si professeurs status="auto" non vérifiés
- Badges : 🤖 Auto (jaune) / ✅ Vérifié (vert)
- Edit : prenom, nom, email, site_web, avatar_url, bio
- Bouton "Marquer comme vérifié" (auto → reviewed)
- UI cohérente avec conventions admin (Tailwind classes standards)

**Autres Fonctionnalités Admin**
- Scraping manuel (bouton "Scraper maintenant")
- Consultation ChangeLogs (historique diffs)
- Édition Events (17 champs modifiables)
- Paramètres globaux (consignes Claude)
- Flash messages auto-dismiss (5s) + bouton fermeture manuelle

---

## 🏗️ Architecture Technique

### Stack

**Backend**
- Rails 8.1.2 (monolithe)
- Ruby 3.2.10 (⚠️ EOL 31 mars 2026)
- PostgreSQL 17.2
- Solid Queue (jobs background)
- Puma web server

**Frontend**
- Turbo (navigation, frames, streams)
- Tailwind CSS v4 (config via @theme dans CSS, PAS tailwind.config.js)
- Stimulus (auto-submit formulaire filtres)
- JavaScript vanilla pour interactions simples

**Scraping**
- HTTParty (fetch HTTP simple)
- playwright-ruby-client 1.58.1 (Chromium headless)
- Nokogiri (parsing HTML)
- ReverseMarkdown (HTML → Markdown)
- Claude CLI (parsing événements)

**Tests**
- Minitest (tests unitaires)
- Capybara + Playwright (tests système)
- Port test : 3002

**Déploiement**
- Docker + docker-compose
- Caddy reverse proxy
- Cloudflare (DNS + HTTPS)
- Tailscale VPN (accès serveur)

### Models (8)

**Event** (événements)
- Relations : belongs_to :professor, belongs_to :scraped_url
- Champs principaux : titre, description, date_debut, date_fin, lieu, prix, type_event, tags
- Scopes : futurs, passes, gratuits, ateliers, stages
- Validations : dates cohérentes, prix >= 0

**Professor** (professeurs)
- Relations : has_many :events, has_many :scraped_urls
- Champs : prenom, nom, nom_normalise (prenom + nom, unique), bio, email, site_web, avatar_url, status (auto/reviewed)
- Compteurs : consultations_count, clics_sortants_count
- Concern : Normalizable (normaliser_nom avec prenom + nom)
- Auto-création : status="auto" quand détecté par Claude, admin review requis

**ScrapedUrl** (sources scraping)
- Relations : has_many :events, has_many :change_logs, has_many :professors
- Champs : url, nom, use_browser, statut_scraping, erreurs_consecutives
- Cache : derniere_version_html, derniere_version_markdown, data_attributes, html_hash
- Notes : commentaire (privé), notes_correctrices (pour Claude)

**ChangeLog** (historique changements)
- Relations : belongs_to :scraped_url
- Champs : changements_detectes (jsonb), diff_html (text)

**NewsletterEmail** (inscriptions newsletter)
- Validations : email format, unicité

**Setting** (paramètres globaux)
- Singleton (1 seule ligne)
- Champs : claude_global_instructions (consignes parsing)

**ProfessorScrapedUrl** (join table)
- Relations : belongs_to :professor, belongs_to :scraped_url

**ProfessorClickTracking** (stats clics)
- Relations : belongs_to :professor
- Champs : clicked_at, ip_address, user_agent

### Routes

**Publiques (français)**
- `GET /` : homepage
- `GET /evenements` : liste événements (avec recherche full-text `?q=`)
- `GET /evenements/:slug` : modal détails (Turbo Frame)
- `GET /professeurs/:id` : profil professeur
- `GET /professeurs/:id/stats` : stats publiques
- `GET /professeurs/:id/redirect_to_site` : tracking + redirect
- `GET /a-propos` : à propos
- `GET /contact` : contact
- `GET /proposants` : proposer événement
- `GET /sitemap.xml` : sitemap SEO
- `POST /newsletter_emails` : inscription newsletter

**Admin (HTTP Basic Auth)**
- `GET /admin` : dashboard
- CRUD `/admin/scraped_urls` (index, show, new, create, edit, update, destroy)
- `POST /admin/scraped_urls/:id/scrape_now` : trigger scraping manuel
- `POST /admin/scraped_urls/:id/fetch_with_httparty` : test HTTParty
- `POST /admin/scraped_urls/:id/fetch_with_playwright` : test Playwright
- `POST /admin/scraped_urls/:id/generate_markdown` : test conversion Markdown
- `GET /admin/scraped_urls/:id/preview` : preview scraping (6 onglets)
- `GET /admin/scraped_urls/:id/raw_html` : HTML brut (iframe)
- `/admin/professors` : index (filtres), edit, update
- `POST /admin/professors/:id/mark_reviewed` : marquer vérifié (auto → reviewed)
- `GET /admin/change_logs` : historique changements
- `GET /admin/events` : liste événements
- `PATCH /admin/events/:id` : édition événement
- `GET /admin/settings/edit` : paramètres globaux

### Services & Libs

**lib/scraping_engine.rb**
- `process(scraped_url)` : orchestrateur scraping complet
- `detect_scraper(scraped_url)` : choisit scraper selon use_browser

**lib/scrapers/html_scraper.rb**
- `fetch(url)` : télécharge HTML avec HTTParty
- Timeout 30s, follow redirects

**lib/scrapers/playwright_scraper.rb**
- `fetch(url)` : télécharge HTML avec Chromium headless
- Timeout 10min (600_000ms)
- Wait networkidle + scroll lazy-loading

**lib/html_cleaner.rb**
- `clean_and_convert(html)` : nettoie HTML + conversion Markdown
- Extrait data-attributes (dates, prix, lieux)
- Supprime scripts, styles, navigation
- Output : markdown, data_attributes, stats réduction

**lib/html_differ.rb**
- `compare(old_html, new_html)` : détecte changements
- Output : changed (bool), lines_added, lines_removed, diff

**lib/claude_cli_integration.rb**
- `parse_and_generate(scraped_url, html, notes_correctrices)` : parsing Claude
- Construit prompt : markdown + data + consignes + notes
- Appelle Claude CLI (timeout 120s)
- Parse JSON events avec professor_nom par event
- Schema : titre, professor_nom, description, date_debut, date_fin, lieu, prix, etc.

**app/jobs/scraping_dispatch_job.rb**
- Cron 24h (Solid Queue)
- Enqueue ScrapingJob pour chaque ScrapedUrl active

**app/jobs/scraping_job.rb**
- Retry 3x avec backoff exponentiel
- Appelle ScrapingEngine.process(scraped_url)

**app/jobs/event_update_job.rb**
- Convertit HTML → Markdown (HtmlCleaner)
- Parse avec Claude CLI (ClaudeCliIntegration)
- `find_or_create_professor(scraped_url, professor_nom)` : recherche 3 niveaux + auto-création
- Crée/update Events en base avec association professor correcte

### Conventions Projet

**Timezone**
- Stockage : UTC en base
- Affichage : Europe/Paris (config.time_zone)

**Localisation**
- Locale par défaut : `fr` (gem rails-i18n)
- Jours/mois en français, capitalisés dans date separators

**Pagination**
- Pagy partout (JAMAIS `.page().per()` Kaminari)
- Syntaxe : `@pagy, @records = pagy(scope, limit: N)`

**Compteurs**
- `increment_counter` (JAMAIS `increment!`)
- Évite N+1 queries

**Scopes temps**
- `Time.current` (JAMAIS `Date.current`)
- Gère timezone correctement

**Jobs Background**
- Solid Queue (pas Sidekiq pour MVP)
- Retry exponentiel 3x
- Logs structurés JSON

**Tests**
- Minitest (pas RSpec)
- Fixtures (pas FactoryBot pour MVP)
- Tests système : Capybara + Playwright local (port 3002)

**Tailwind CSS v4**
- ⚠️ `tailwind.config.js` ne fonctionne PLUS pour les couleurs
- Méthode correcte : `@theme` dans `app/assets/tailwind/application.css`
- Exemple : `--color-moutarde: #D4A017;` → utilise `bg-moutarde`
- Recompiler : `bin/rails tailwindcss:build` + relancer serveur

**Routes publiques**
- Français : /evenements, /professeurs (PAS /events, /teachers)

**Mobile**
- Viewport : `user-scalable=no` (zoom désactivé pour éviter scroll horizontal)

---

## 📚 Epics Terminés (100%)

### Epic 1: Infrastructure & Deployment
- PostgreSQL local + production
- 8 models avec validations
- Seeds réalistes (5 profs, 15 events, 2 scraped_urls)
- Solid Queue pour jobs background
- Docker + Caddy + HTTPS Cloudflare
- Déploiement production complet

### Epic 2: Homepage & Design System
- Design system terracotta/beige
- Homepage Hero responsive
- Navigation desktop/mobile (burger menu)
- Composants réutilisables (Tags, Pills)
- Accessibilité WCAG 2.1 AA

### Epic 3: Automated Scraping Engine
- HtmlDiffer pour détection changements
- Claude CLI Integration Service
- ScrapingJob avec retry + logging
- ScrapingDispatchJob (orchestration 24h)
- Event deduplication & conflict resolution
- Admin interface ScrapedUrls management
- HTML → Markdown conversion (98.7% réduction)
- PlaywrightScraper pour sites JavaScript

### Epic 4: Event Discovery & Browsing
- Liste événements chronologique
- Infinite scroll (Pagy)
- Event modal avec détails complets
- Turbo Frame navigation

### Epic 5: Event Filtering & Search
- Filtres date (date picker)
- Filtres type (atelier/stage)
- Filtres format (en ligne/présentiel)
- Filtres prix (gratuit/payant)
- Recherche full-text multi-mots (AND)
- Reset filtres
- Auto-submit temps réel

### Epic 6: Newsletter Subscription
- Formulaire newsletter (sidebar + footer)
- Validation email
- Flash messages succès/erreur
- Admin : consultation liste emails

### Epic 7: Professor Profiles & Stats
- Page profil professeur
- Bio + photo + site web
- Liste événements du professeur
- Stats publiques (vues + clics sortants)
- Redirect tracking vers site professeur

### Epic 8: SEO & Discoverability
- Meta tags dynamiques (OG, Twitter)
- JSON-LD schema.org (Event, Person)
- Sitemap.xml dynamique
- Cache sitemap (1h)
- robots.txt

### Epic 9: Admin Interface
- Admin dashboard
- CRUD ScrapedUrls
- Preview HTML avec 6 onglets
- Trigger scraping manuel
- Test scraping (4 boutons : HTTParty, Playwright, Markdown, Claude)
- Change logs consultation
- HTTP Basic Auth

---

## 🔧 Outils Développement

**Mode debug design** : `Ctrl+Shift+D`
- Affiche ID éléments au hover
- Affiche classes CSS
- Affiche contenu texte
- Infobulle centrée fond vert pistache

**Sync état projet** : `bin/sync-gist.sh`
- Synchronise docs/etat-projet.md vers Gist GitHub secret
- Permet à claude.ai de lire l'état projet (repo privé inaccessible)
- Credentials : ~/.env-stopanddance (GIST_ID, GIST_TOKEN)

**Commandes utiles**
```bash
# Dev
bin/rails s -b 0.0.0.0 -p 3002  # Serveur dev (bind 0.0.0.0 obligatoire)
bin/rails test                  # Tests unitaires
bin/rails test:system           # Tests système
bin/rubocop                     # Lint code
bin/brakeman -w 2               # Scan sécurité
bin/sync-gist.sh                # Sync état projet

# Production
ddup                            # Start prod (alias docker compose up)
dddown                          # Stop prod
docker compose logs -f web      # Voir logs

# Scraping
bin/rails scraping:run[1]       # Scraper URL ID 1
bin/rails scraping:test[1]      # Test parsing sans sauvegarder
```

---

## 📖 Documentation

**Guides utilisateur**
- `docs/guide-admin.md` : utilisation interface admin
- `docs/guide-scraping.md` : ajouter URL, lancer scraping, debugging

**Documentation technique**
- `docs/architecture-scraping.md` : flux scraping complet, composants, performance
- `docs/ui-reference.md` + `docs/ui-reference.jsx` : maquettes UI
- `CLAUDE.md` : conventions projet, règles développement

**Documentation centrale**
- `docs/README.md` : navigation toutes les docs, quick start

**Documentation vérification**
- `docs/verification-scraping.md` : protocole complet vérification résultats scraping (8 sections, 14 checkpoints)

---

## 🚀 Session 2026-04-05 → 2026-04-09 (Remote Control depuis mobile)

### Corrections Mobile (main) ✅

**Commits :**
- `b538c1e` fix: Empêcher le scroll horizontal sur mobile (overflow-x hidden)
- `82b967a` fix: Corriger débordement horizontal des tags sur mobile (events) — flex-wrap sur vignettes
- `76ffba9` fix: Bloquer zoom mobile pour empêcher scroll horizontal — viewport `user-scalable=no` (cause réelle du problème)
- `99b6eb3` feat: Champ recherche full-text multi-mots (AND) dans filtres agenda — recherche titre/description/lieu/adresse/tags/professeur
- `a6540f0` feat: Vignettes Atelier/Présentiel + jours en français capitalisés — gem rails-i18n, locale fr par défaut
- `7462abd` fix: Cartes événements pleine largeur sur mobile + prix réduit compact — rounded-none sur mobile, format 20,00€/16,00€
- `c34f15e` feat: Lien Admin dans menu burger mobile

**Problèmes résolus :**
- Scroll horizontal mobile : causé par le zoom (pinch), corrigé par `user-scalable=no` dans viewport meta
- Tags qui débordaient : ajout `flex-wrap` sur la ligne des pastilles
- Vignettes en anglais : Workshop → Atelier (locale en corrigée), locale par défaut passée à `fr`
- JS auto-submit ne fonctionnait pas pour le champ recherche : le fichier JS réellement servi était dans `app/assets/javascripts/` (pas `app/javascript/`), ancien contenu sans méthode `submit()`. Corrigé en ajoutant listener `input` avec debounce directement dans le fichier servi.

**Leçon apprise (mémorisée) :** Toujours vérifier visuellement avec screenshots Playwright (mobile + desktop) AVANT de dire à Duy de tester. Règle 2d du CLAUDE.md.

### Feature Branch : Exploration Site Prof (en cours)

**Branche :** `exploration-site-prof` (créée depuis `c34f15e`)

**Tech-spec BMAD créée :** `_bmad-output/implementation-artifacts/tech-spec-wip.md`
- Status : `review` (étapes 1-3 complétées, étape 4 review en attente)
- Gist pour audit claude.ai : https://gist.github.com/Aujourduy/a50be0d59e19801597527c22eb1de7ee

**Fonctionnalité prévue :**
- Crawler récursif de sites de profs (à partir d'une URL racine)
- Détection des pages ateliers/stages via LLM gratuit (OpenRouter)
- Classification binaire oui/non (pas d'extraction)
- Création automatique de ScrapedUrl pour pages classées "oui"
- Re-crawl automatique si page racine modifiée
- Config modèle LLM : global dans admin settings + override par scan
- Limites : profondeur max 5, max 100 pages, même domaine

**Spec complète :** 35 tâches en 8 phases, 20 critères d'acceptation Given/When/Then

### Implémentation Crawler (2026-04-06 → 2026-04-07) ✅

**Commits branche `exploration-site-prof` :**
- `db9c0e8` feat: Crawler site prof avec détection LLM via OpenRouter (implémentation complète)
- `50e3e2b` fix: Retry 3x avec backoff sur rate limit 429 OpenRouter
- `9d198fa` fix: Crawler utilise HTTParty (rapide) au lieu de Playwright
- `0d143f6` feat: Fallback Playwright automatique pour pages JS-only

**Tests réels :**
- Silvestre (Wix) : 12 pages crawlées, 6 OUI, ~30s ✅
- Wilberforce (Wix) : 25 pages crawlées, 14 OUI, ~4 min ✅

**Problèmes résolus :**
- Rate limit OpenRouter sur modèles gratuits → retry 3x avec backoff 15/30/45s
- Playwright trop lent/crash sur crawl multi-pages Wix → HTTParty par défaut pour crawler
- Pages JS-only (contenu vide côté serveur) → détection automatique (texte visible < 500 chars OU `<noscript>` JavaScript) + fallback Playwright

### DaisyUI 5 (mergé dans main) ✅

- Thème custom `stopanddance` (terracotta/beige/noir)
- Toutes pages publiques + admin migrées vers composants DaisyUI
- Guide : `docs/guide-daisyui.md`

### Récurrence events ✅

- RecurrenceExpander : weekly → dates individuelles (aujourd'hui → 31 août)
- Dates explicites : Claude retourne N events séparés
- Exclusions : dates isolées + périodes
- Testé : Marc (38 events), Peter (79 events)

### Séparation date/heure ✅

- `date_debut_date` (date) + `heure_debut` (time nullable)
- Horaire non renseigné = nil (pas d'invention)
- Modal : "Horaires à confirmer" si heure inconnue
- Backward compat : setter `date_debut=` auto-remplit les nouveaux champs

### Autres améliorations ✅

- Clean slate à chaque re-parsing (supprime events avant recréation)
- Recherche agenda : inclut prénom du prof
- Normalisation titres majuscules + acronymes préservés (configurable admin)
- Synonymes danse : vague=atelier, intensif=stage
- Avatars Cloudinary importés (17 profs)
- Avatars dans admin professors index
- Admin profs : colonnes Photo/Prénom/Nom, recherche AND, tous affichés
- Modal event : prénom+nom, boutons source/site distincts, URL référence
- Infinite scroll fixé (replace au lieu d'append)
- Durée affichée en XXmin ou XXhXXmin

---

## ⚠️ TODO Prochaine Session

### Session 2026-04-09 (suite) ✅

**Photos locales :**
- Migration Cloudinary → `public/photos/professors/` (une seule taille 300px)
- ProfessorPhotoService : upload + crop auto MiniMagick
- Admin edit : champ file upload avec preview photo actuelle
- Auto-download photos depuis sites profs (33 profs avec photo sur 65)
- Prompt Claude : `professor_photo_url` pour auto-download au parsing
- Alerte + filtre "Sans photo" dans admin professors
- `/admin` restreint au réseau Tailscale (100.64.0.0/10) + HTTP Basic Auth

**Admin Jobs :**
- Page `/admin/jobs` : stats, jobs en attente/cours, échoués (relancer/supprimer), recurring
- Lien Jobs dans navbar admin

**Scraping complet lancé :**
- 144 events futurs sur l'agenda
- 20 URLs réelles scrapées
- Quelques erreurs (null byte PDF, retry) — non bloquantes

---

### Session 2026-04-11 → 2026-04-14 ✅

**Tests automatisés QA :**
- `scraping:dry_run` — vérifie fetch + markdown sur toutes URLs actives (27 URLs, 20 OK, 7 erreurs connues)
- `scraping:verify` — Claude compare screenshots vs events DB (match/partial/mismatch)
- `scraping:missing` — Claude détecte events sur le site absents de DB (4 faux positifs identifiés)
- Documentation complète : `docs/scraping-urls.md`

**Déduplication events :**
- Cross-URL : même prof + date + heure depuis 2 URLs → garde le plus complet (18 doublons supprimés)
- Intra-URL : explicite > récurrent (flag `generated_from_recurrence`)
- 0 doublons restants

**Autres :**
- URL #9 (Peter Wilberforce) passée en `use_browser: true` (Playwright) pour récupérer le contenu JS-only en bas de page
- Rubocop : 16 offenses autocorrigées, 0 restantes
- Infinite scroll sur toutes les pages admin (professors, site_crawls, notifications, jobs)

---

### Session 2026-04-18 → 2026-04-19 ✅

**Robustesse jobs Solid Queue :**
- `retry_on wait: :exponentially_longer` → `:polynomially_longer` (4 jobs : ApplicationJob, ScrapingJob, EventUpdateJob, SiteCrawlJob). `exponentially_longer` est déprécié Rails 8 et provoquait `Couldn't determine a delay` silencieux en retry.
- Timeout réel sur Claude CLI (`lib/claude_cli_integration.rb`) : `Open3.popen2e` + `IO.select` + `Process.kill TERM/KILL`. Constante `TIMEOUT_SECONDS = 120` désormais appliquée. Avant : `Open3.capture2e` sans wrapper, un CLI pendu bloquait 1 des 3 threads workers indéfiniment.
- Test E2E OK (CLI 57s, 14 events parsés via perform_later + worker Solid Queue).
- Nettoyage 2 FailedExecution orphelines.

**Audit QA complet 2026-04-19 (rapport `tmp/QA_AUDIT_2026-04-19.md`) :**
- Minitest 110/110 tests ✅, system 8/8 ✅, rubocop 0 offense ✅, brakeman 0 issue critique ✅
- `scraping:dry_run` 20/20 URLs réelles OK (7 seeds example.com supprimées avec leurs events/profs/changelogs)
- Checklist SQL 12/12 items (0 event orphan, 0 doublon, 0 date inversée, 0 prix incohérent)
- Routes : 9/9 publiques 200, 4/4 admin 403 (Tailscale filter actif)
- **UX Playwright 49/49 (100%)** via `script/ux-audit.js` : mobile (5 pages sans scroll horizontal), burger + drawer + navigation clic "Agenda" + Escape, homepage (clic AGENDA, saisie newsletter), agenda (badges, jours français), filtres complets (recherche q=paris/silvestre/xxx/reset, checkboxes gratuit/stage/en_ligne, lieu via request sniffing), modal (clic carte, bouton ×, clic overlay), clic "Voir stats" → /stats, infinite scroll 30→60, footer links 200, SEO.
- **Bug corrigé :** `app/javascript/controllers/modal_controller.js` créé (actions `close` + `stopPropagation`). Les vues utilisaient `data-controller="modal"` mais le fichier n'existait pas → clic overlay modal inerte. Désormais fonctionnel.
- Nettoyage : seeds fictifs supprimés (16 events + 5 changelogs + 7 URLs + 5 profs), `db/seeds.rb` vidé, 10 events orphans scraped_url_id=NULL purgés

---

## ⚠️ TODO Prochaine Session

**Priorité 1 — Améliorations scraping :**
- Support récurrence monthly dans RecurrenceExpander
- Checkbox `auto_recrawl` dans formulaire admin ScrapedUrl
- Scraper les 5 profs restants sans photo (Desboist, Omnès, Jones, Chantereau+Sartelet)

**Priorité 2 — Architecture :**
- Co-animation (table join event_professors pour multi-profs par event)
- Page admin notifications : intégrer plus d'alertes auto (erreurs scraping, nouveaux profs)

**Priorité 3 — Maintenance :**
- Optionnel : Upgrade Ruby 3.4

---

## 📝 Sessions Précédentes (Archives)

### Session 2026-04-05 — Remote Control ❌

**Objectif :** Configurer Claude Code Remote Control pour piloter le serveur depuis mobile/navigateur.

**Problème identifié :**
- Token OAuth actuel a scopes `["user:inference","user:profile"]` — il manque `user:sessions:claude_code`
- `claude auth login` en headless SSH ne propose pas de prompt pour coller le code OAuth

**Résolu dans la session suivante :** Remote Control fonctionne, utilisé pour toutes les corrections mobile.

### Session 2026-04-01 — Import Masse + Admin ✅

**Commits :**
- `3f290a1` feat: Import masse + filtres/tri admin scraped_urls
- `f681991` fix: Force timestamp update même si HTML/Markdown inchangé
- `c0e6751` docs: Ajout protocole vérification scraping complet
- `6a756df` feat: Ajout champ prenom aux professors avec split prenom/nom
- `03be341` feat: Auto-création professors multi-profs + admin review
- `fd8a174` refactor: Harmonise UI page /admin/professors/edit avec conventions admin

### Session 2026-03-31 — Playwright ✅

**Correction critique :** `waitUntil: "networkidle"` → `"domcontentloaded"` (75x plus rapide sur Wix)
**Tests complets :** 89 tests unitaires + 8 tests système, 0 failures

### Session 2026-03-28 — Interface Admin Scraping ✅

**Fonctionnalités :** PlaywrightScraper, 4 boutons test, badges mode, flash auto-dismiss
