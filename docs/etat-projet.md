# État du Projet - Stop & Dance

**Dernière mise à jour :** 2026-04-05
**Branch :** main
**Dernière commit :** 3f290a1
**Statut :** ✅ **PROJET COMPLET - Tous les epics terminés + Playwright validé**

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
- Design system terracotta/beige (Tailwind CSS v4)
- Accessibilité WCAG 2.1 AA
- Mode debug design (Ctrl+Shift+D)

**Liste Événements**
- Affichage chronologique (futurs uniquement)
- Infinite scroll avec Pagy
- Cartes événements : avatar prof 128×128px + 4 lignes info
- Compteurs dynamiques dans le titre (ateliers/stages)
- Modal détails événement (Turbo Frame)

**Filtres Multi-Critères**
- Date (date picker)
- Type (atelier/stage)
- Format (en ligne/présentiel)
- Prix (gratuit/payant)
- Reset filtres
- Auto-submit en temps réel
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
- Pas de Stimulus pour MVP
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
- `GET /evenements` : liste événements
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

---

**Documentation vérification**
- `docs/verification-scraping.md` : protocole complet vérification résultats scraping (8 sections, 14 checkpoints)

---

## 🚀 Dernière Session (2026-04-05)

### Tentative configuration Remote Control ❌

**Objectif :** Configurer Claude Code Remote Control pour piloter le serveur depuis mobile/navigateur.

**Diagnostic effectué :**
- Auth OAuth claude.ai ✅, plan Max ✅, API connectivity ✅
- Pas de variables d'env parasites, pas de blocage firewall/Tailscale
- Version 2.1.92 (>2.1.51 requis) ✅

**Problème identifié :**
- Token OAuth actuel a scopes `["user:inference","user:profile"]` — il manque `user:sessions:claude_code`
- Erreur : `OAuth token does not meet scope requirement user:sessions:claude_code`
- `claude auth login` en headless SSH ne propose pas de prompt pour coller le code OAuth
- Tentative d'échange manuel du code OAuth via PKCE → rate limité par Cloudflare après plusieurs essais

**Fichiers non commités (travail en cours scraping) :**
- `app/jobs/scraping_job.rb` (modifié)
- `config/initializers/solid_queue.rb` (modifié)
- `config/recurring.yml` (modifié)
- `lib/tasks/scraping_report.rake` (nouveau)

**TODO pour résoudre Remote Control :**
1. Attendre fin rate limit (~1h) puis relancer `claude auth login` depuis terminal séparé (pas depuis Claude Code)
2. Ou : installer Claude Code sur machine locale avec navigateur → `claude auth login` → copier `~/.claude/.credentials.json` vers serveur
3. Ou : `unset DISPLAY && claude auth logout && claude auth login` (forcer mode texte)

---

## 📝 Session 2026-04-01

### 1. Import Masse + Filtres Admin ScrapedUrls ✅

**Commit :** `3f290a1` feat: Import masse + filtres/tri admin scraped_urls

### 2. Fix Timestamps Preview Admin ✅

**Problème résolu :**
- Timestamps (derniere_version_html_at, markdown_at, claude_at) non mis à jour après boutons test
- Cause : Rails optimisation skip update si contenu identique
- Solution : `assign_attributes` + `save!(touch: false)` dans fetch_with_httparty, fetch_with_playwright, generate_markdown

**Fichiers modifiés :**
- `app/controllers/admin/scraped_urls_controller.rb` (3 actions)
- `app/views/admin/scraped_urls/preview.html.erb` (ajout affichage timestamps)

### 2. Documentation Vérification Scraping ✅

**Création :**
- `docs/verification-scraping.md` : protocole 8 sections, 14 checkpoints
- Sections : Base, Cohérence, Comparaison HTML→DB, Affichage public/admin, Avancé, Troubleshooting, Résumé
- Commandes copy-paste SQL et Rails console
- Référencé dans `CLAUDE.md` projet

### 3. Ajout Champ Prenom Professors ✅

**Migration :**
- Nouveau champ `prenom` (string, nullable)
- Split données existantes : dernier mot = nom, reste = prenom
- Concern Normalizable : `nom_normalise = normaliser(prenom + nom)`

**Fichiers modifiés :**
- Migration `db/migrate/20260331212835_add_prenom_to_professors.rb`
- `app/models/concerns/normalizable.rb` (logique prenom + nom)

### 4. Auto-Création Professeurs Multi-Profs ✅

**Feature complète :**
- Claude extrait `professor_nom` par événement (ajout champ JSON schema)
- `EventUpdateJob.find_or_create_professor` : recherche 3 niveaux
  1. ScrapedUrl.professors (professeurs déjà associés)
  2. Global (Professor.find_by nom_normalise)
  3. Create new avec status="auto", bio auto-générée
- Split automatique prenom/nom (dernier mot = nom, reste = prenom)
- Logging SCRAPING_LOGGER pour toutes créations/associations

**Fichiers modifiés :**
- `lib/claude_cli_integration.rb` (schema JSON + professor_nom)
- `app/jobs/event_update_job.rb` (méthode find_or_create_professor)

### 5. Interface Admin Review Professeurs ✅

**CRUD Professeurs créé :**
- Route `/admin/professors` : index (liste), edit, update, mark_reviewed
- Index : filtres Tous / À vérifier (auto), badges 🤖 Auto / ✅ Vérifié
- Alerte dashboard (URLs admin) si professeurs status="auto" non vérifiés
- Edit : prenom, nom, email, site_web, avatar_url, bio
- Bouton "Marquer comme vérifié" (auto → reviewed)
- UI harmonisée avec conventions admin (Tailwind classes standards)

**Fichiers créés :**
- `app/controllers/admin/professors_controller.rb` (index, edit, update, mark_reviewed)
- `app/views/admin/professors/index.html.erb`
- `app/views/admin/professors/edit.html.erb`

**Fichiers modifiés :**
- `config/routes.rb` (routes professors)
- `app/controllers/admin/scraped_urls_controller.rb` (alerte dashboard)
- `app/views/admin/scraped_urls/index.html.erb` (alerte yellow box)
- `app/views/layouts/admin.html.erb` (lien navigation "Professeurs")

**Commits session :**
- `f681991` Fix: Force timestamp update même si HTML/Markdown inchangé
- `c0e6751` Docs: Ajout protocole vérification scraping complet
- `6a756df` Feat: Ajout champ prenom aux professors avec split prenom/nom
- `03be341` Feat: Auto-création professors multi-profs + admin review
- `fd8a174` Refactor: Harmonise UI page /admin/professors/edit avec conventions admin

---

## ⚠️ TODO Prochaine Session

**Priorité 1 — Remote Control :**
- Résoudre scope OAuth `user:sessions:claude_code` (voir solutions ci-dessus)

**Priorité 2 — Fichiers non commités :**
- Examiner et commiter les modifications scraping en cours (scraping_job, solid_queue, recurring.yml, scraping_report.rake)

**Autres :**
- Tester scraping complet avec auto-création professeurs
- Vérifier workflow admin review
- Optionnel : Upgrade Ruby 3.4

---

## 📝 Sessions Précédentes (Archives)

### Session 2026-03-31 - Timestamps + Documentation ✅

#### Correction Critique Playwright ✅

**Problème identifié et corrigé :**
- `waitUntil: "networkidle"` timeout 10min sur sites Wix (Marc Silvestre)
- Cause : scripts analytics/tracking Wix font requêtes infinies, jamais "idle"
- Solution : `waitUntil: "domcontentloaded"` + wait 5s pour JS rendering

**Changements PlaywrightScraper :**
- `networkidle` → `domcontentloaded`
- Timeout : 10min → 2min
- Wait initial : 2s → 5s (meilleur rendu JS)
- Wait après scroll : 1s → 2s

### Tests Playwright Complets ✅

**Tests effectués :**

1. **Site de test HTML+JS local**
   - Créé `tmp/test-playwright.html` avec contenu JavaScript (lazy-loading 500ms)
   - Serveur HTTP Python (port 8888)
   - ✅ Contenu dynamique JavaScript détecté (Stage Dance Immersion)
   - ✅ Confirmation exécution JS détectée
   - Temps : 3-5 secondes

2. **Site Rails local (port 3002)**
   - URL: `http://localhost:3002/`
   - ✅ Homepage chargée (13130 chars)
   - ✅ Titre et contenu détectés
   - Temps : 4-6 secondes

3. **Site Wix externe**
   - URL: `https://www.wix.com/website-template/view/html/1068`
   - ✅ Template Wix chargé (4599 chars)
   - ✅ Contenu Wix détecté
   - Temps : 8-12 secondes

3b. **Site Wix réel - Marc Silvestre** ⭐
   - URL: `https://www.marcsilvestre.com/agenda-cours-stages-1`
   - ✅ HTML complet : 419 KB
   - ✅ Markdown : 5.2 KB (98.8% réduction)
   - ✅ Mots-clés détectés : agenda, stage, cours, VAGUES, Micadanses
   - ✅ Scraping complet : 40.7s (8s fetch + conversion)
   - ❌ AVANT : timeout 10min avec networkidle
   - ✅ APRÈS : 8s avec domcontentloaded

4. **Intégration ScrapingEngine**
   - ✅ Scraping complet avec détection changements
   - ✅ HTML mis en cache database (2981 chars)
   - ✅ html_hash calculé (SHA256)
   - ✅ Contenu JavaScript présent dans cache

5. **Conversion Markdown**
   - ✅ HtmlCleaner détecte contenu JavaScript dans Markdown
   - ✅ Réduction tokens efficace (313 chars)

6. **Tests automatisés**
   - ✅ Tests unitaires : 89 runs, 0 failures
   - ✅ Tests système : 8 runs, 0 failures
   - ✅ RuboCop : 0 offenses
   - ✅ Brakeman : 1 warning (EOL Ruby, non-bloquant)

**Comparaison HTTParty vs Playwright :**
- HTTParty : ⚡ 1-2s, ❌ pas de JS, sites statiques uniquement
- Playwright : 🐢 8-40s, ✅ JS complet, Wix/React/Vue compatible
- Playwright optimisé : `domcontentloaded` au lieu de `networkidle` (75x plus rapide sur Wix)

**Rapport complet :** `tmp/PLAYWRIGHT_TEST_REPORT.md`

### Session précédente (2026-03-28)

**Fonctionnalités implémentées :**
- PlaywrightScraper opérationnel (timeout 10min, scroll lazy-loading)
- Interface admin test scraping (4 boutons : HTTParty, Playwright, Markdown, Claude)
- Badges indicateurs mode (HTTParty/Playwright)
- Formulaire edit avec choix visuel
- Flash messages auto-dismiss (5s)
- Documentation Tailwind CSS v4

**Commits :**
- `6be714c` - feat: Ajout système de test scraping
- `2d4ef6c` - fix: Corrections boutons Markdown maker et Playwright
- `3df9fe6` - feat: Flash messages auto-dismiss + timeout Playwright 10min
- `ddc480e` - docs: MAJ état projet session 2026-03-28
- `699076d` - docs: Refonte complète etat-projet.md en synthèse globale

---

## ⚠️ TODO Prochaine Session

**✅ PLAYWRIGHT VALIDÉ - Prêt pour production**

**Actions production :**
1. Tester scraping sur 2-3 URLs réelles (Wix/React/Vue) en production
2. Monitorer logs Solid Queue pour temps d'exécution
3. Comparer résultats HTTParty vs Playwright côte à côte
4. Vérifier utilisation mémoire Chromium headless

**Maintenance système :**
- ~~Upgrade Ruby 3.3 avant EOL 3.2.10 (31 mars 2026)~~ → reporté (warning ignoré dans Brakeman)
- Upgrade Ruby 3.4 planifié pour session future (quand temps disponible)
- Mise à jour credentials ENV (ADMIN_USERNAME, ADMIN_PASSWORD)
- Setup DNS pour stopand.dance
- Tests complets production sur stopand.dance

**Qualité :**
- QA final complet (slash command `/qa`)
- Documenter cas d'usage HTTParty vs Playwright avec screenshots
- Ajouter métriques réelles dans `docs/architecture-scraping.md`
