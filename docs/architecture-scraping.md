# Architecture Scraping - Stop & Dance

## Vue d'ensemble

Le système de scraping automatique récupère les événements de danse depuis des sites web externes, les convertit en format optimisé, et utilise Claude AI pour extraire les informations structurées.

## Flux complet

```
┌─────────────────────────────────────────────────────────────────────┐
│ SOLID QUEUE (ScrapingDispatchJob - toutes les heures)              │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ├─> Pour chaque ScrapedUrl active
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ ScrapingJob (1 job par URL)                                        │
│                                                                     │
│  └─> ScrapingEngine.process(scraped_url)                          │
│      │                                                              │
│      ├─> 1. Détection scraper (HtmlScraper ou Playwright)         │
│      │    • use_browser=false → HTTParty (sites statiques)        │
│      │    • use_browser=true → Playwright (sites JavaScript)      │
│      │                                                              │
│      ├─> 2. Téléchargement HTML                                    │
│      │    • Playwright: lance Chromium headless                    │
│      │    • Attend chargement JS                                   │
│      │    • Récupère HTML final                                    │
│      │                                                              │
│      ├─> 3. Calcul html_hash (SHA256)                             │
│      │                                                              │
│      ├─> 4. Détection changements (HtmlDiffer)                    │
│      │    • Compare html_hash avec version précédente             │
│      │    • Analyse diff pour détecter modifications              │
│      │                                                              │
│      └─> 5. Si changements détectés:                              │
│           ├─> Stocke HTML + html_hash en DB                       │
│           ├─> Crée ChangeLog (diff HTML)                          │
│           └─> Enqueue EventUpdateJob                              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ EventUpdateJob (seulement si changements détectés)                 │
│                                                                     │
│  ├─> 1. HtmlCleaner.clean_and_convert(html)                       │
│  │    ├─> Supprime scripts, styles, navigation                    │
│  │    ├─> Extrait data-attributes (dates, prix, lieux)           │
│  │    └─> Conversion HTML → Markdown                              │
│  │        • 98.7% de réduction (419 KB → 5 KB)                    │
│  │        • Format natif de Claude                                 │
│  │                                                                  │
│  ├─> 2. Stocke Markdown + data_attributes en DB                   │
│  │                                                                  │
│  ├─> 3. ClaudeCliIntegration.parse_and_generate()                │
│  │    ├─> Construit prompt avec:                                  │
│  │    │    • Markdown nettoyé                                      │
│  │    │    • Data-attributes structurés                            │
│  │    │    • Consignes globales (Setting)                         │
│  │    │    • Notes correctrices (par URL)                         │
│  │    │                                                             │
│  │    ├─> Envoie prompt à Claude CLI                              │
│  │    │    • Timeout: 120s                                         │
│  │    │    • Mode headless (--dangerously-skip-permissions)       │
│  │    │                                                             │
│  │    └─> Reçoit JSON avec liste d'événements                     │
│  │                                                                  │
│  └─> 4. Création/update Events en DB                              │
│       ├─> Pour chaque event dans le JSON:                         │
│       │    • Parse dates (ISO 8601)                                │
│       │    • Calcule type_event par durée (<5h = atelier)         │
│       │    • Find_or_initialize_by (url + date + titre)           │
│       │    • Sauvegarde en DB                                      │
│       │                                                             │
│       └─> Log résultats (nombre events créés/updatés)            │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Composants détaillés

### 1. ScrapingDispatchJob
**Rôle:** Orchestrateur principal
**Schedule:** Toutes les heures (cron via Solid Queue)
**Logique:**
- Récupère toutes les ScrapedUrl avec `statut_scraping: "actif"`
- Enqueue un ScrapingJob pour chaque URL
- Log global de début/fin de dispatch

### 2. ScrapingJob
**Queue:** `:scraping`
**Retry:** 3 tentatives avec backoff exponentiel
**Logique:**
- Vérifie que l'URL est toujours active
- Appelle ScrapingEngine.process(scraped_url)
- Log succès/échec

### 3. ScrapingEngine
**Rôle:** Orchestrateur du scraping par URL
**Méthodes:**
- `process(scraped_url)` - Point d'entrée principal
- `detect_scraper(url)` - Détermine quel scraper utiliser

**Détection scraper:**
```ruby
if scraped_url.use_browser
  Scrapers::PlaywrightScraper.fetch(url)
else
  Scrapers::HtmlScraper.fetch(url) # HTTParty
end
```

**Détection changements:**
```ruby
new_hash = Digest::SHA256.hexdigest(html)
if new_hash != scraped_url.html_hash
  # Changements détectés
end
```

### 4. Scrapers::HtmlScraper
**Usage:** Sites statiques (HTML simple)
**Tech:** HTTParty
**Features:**
- User-Agent personnalisé
- Respect robots.txt
- Timeout 30s
- Follow redirects

### 5. Scrapers::PlaywrightScraper
**Usage:** Sites JavaScript (React, Vue, Wix, etc.)
**Tech:** Playwright (Chromium headless)
**Features:**
- Lance navigateur complet
- Attend chargement page + JS (networkidle)
- Scroll automatique pour lazy-loading
- Screenshot pour debug
- Timeout 60s

**Exemple sites nécessitant Playwright:**
- Wix (Marc Silvestre)
- Sites React/Vue
- Calendriers dynamiques

### 6. HtmlCleaner
**Rôle:** Nettoyage et conversion HTML → Markdown
**Méthode:** `clean_and_convert(html)`

**Étapes:**
1. Parse HTML avec Nokogiri
2. Extrait data-attributes **avant** nettoyage
3. Supprime le bruit:
   - `<script>`, `<style>`, `<noscript>`
   - `<nav>`, `<footer>`, `<aside>`
   - Cookies, analytics, tracking
4. Conversion Markdown avec ReverseMarkdown
5. Retourne:
   ```ruby
   {
     markdown: "...",
     data_attributes: { dates: [...], prices: [...] },
     original_size_kb: 419.5,
     markdown_size_kb: 5.3,
     reduction_percent: 98.7
   }
   ```

**Data-attributes extraits:**
- `[data-event]`, `[data-date]`, `[data-start]`, `[data-end]`
- `[data-price]`, `[data-cost]`
- `[data-location]`, `[data-venue]`

### 7. ClaudeCliIntegration
**Rôle:** Interface avec Claude AI
**CLI Path:** `~/.nvm/versions/node/v22.21.1/bin/claude`
**Timeout:** 120 secondes

**Prompt construit:**
```
Tu es un assistant de parsing d'événements de danse.

Le contenu de la page est fourni en Markdown.
Focus sur les titres (###), listes (-), et gras (**).

[CONSIGNES GLOBALES]
[NOTES CORRECTRICES]
[DONNÉES STRUCTURÉES]

Retourne un JSON avec cette structure:
{
  "events": [
    {
      "titre": "...",
      "date_debut": "2026-03-25T19:30:00+01:00",
      "date_fin": "2026-03-25T21:30:00+01:00",
      "lieu": "Paris",
      "prix_normal": 25.00,
      "tags": ["Contact Improvisation"]
    }
  ]
}

CONTENU MARKDOWN:
[markdown nettoyé]
```

**Parsing réponse:**
- Extrait JSON de la sortie CLI
- Parse avec symbolize_names
- Retourne hash avec `:events`

### 8. EventUpdateJob
**Queue:** `:scraping`
**Retry:** 3 tentatives
**Logique:**

**Pour chaque event du JSON Claude:**
1. Skip si dates manquantes
2. Parse dates ISO 8601
3. Calcule type_event:
   ```ruby
   duration_hours = (date_fin - date_debut) / 3600.0
   type_event = duration_hours < 5 ? "atelier" : "stage"
   ```
4. Find_or_initialize_by:
   - `scraped_url_id`
   - `date_debut`
   - `titre`
5. Assign attributes et save

## Stockage en base

### ScrapedUrl
```ruby
derniere_version_html       # HTML complet (419 KB)
derniere_version_markdown   # Markdown nettoyé (5 KB)
data_attributes            # JSONB - data-* extraits
html_hash                  # SHA256 du HTML
use_browser                # Boolean - utiliser Playwright ?
notes_correctrices         # Text - instructions spécifiques
statut_scraping            # Enum - actif/inactif/erreur
erreurs_consecutives       # Integer - compteur erreurs
```

### Event
```ruby
titre
description
date_debut, date_fin
lieu, adresse_complete
prix_normal, prix_reduit
type_event                 # Enum - atelier/stage (calculé par durée)
gratuit                    # Boolean
en_ligne, en_presentiel    # Boolean
tags                       # Array de strings
professor_id               # belongs_to
scraped_url_id             # belongs_to
```

## Optimisations

### 1. Réduction tokens Claude
- HTML brut: **419 KB** (Marc Silvestre, site Wix lourd)
- Après nettoyage + Markdown: **5 KB**
- **Réduction: 98.7%**
- **Coût API: $0.04** au lieu de $0.30 par scraping

### 2. Détection changements efficace
- `html_hash` (SHA256) calculé à chaque scraping
- Comparaison O(1) au lieu d'analyser tout le HTML
- EventUpdateJob lancé **seulement si changements**

### 3. Cache HTML pour debug
- HTML original conservé en DB
- Permet re-parsing sans re-scraping
- Preview admin avec 4 onglets:
  - Résultat parsing (JSON)
  - Markdown envoyé à Claude
  - Data-attributes extraits
  - HTML brut original

## Configuration

### Consignes globales Claude
**Location:** Admin → Paramètres → Consignes globales
**Stockage:** `Setting.instance.claude_global_instructions`
**Usage:** Ajoutées à tous les prompts

**Exemple:**
```
- Toujours extraire les dates au format ISO 8601
- Si le prix n'est pas mentionné, mettre null
- Détecter automatiquement les événements gratuits
- Tags: utiliser les noms exacts des styles de danse
```

### Notes correctrices par URL
**Location:** ScrapedUrl.notes_correctrices
**Usage:** Instructions spécifiques à un site

**Exemple:**
```
- Les "Vagues" de Marc Silvestre sont des cours hebdomadaires
- Prix standard: 20€ (17€ réduit)
- Tous les vendredis 19h30-21h30
```

## Logs et monitoring

### SCRAPING_LOGGER
**Path:** `log/scraping.log`
**Format:** JSON structuré

**Events logged:**
```ruby
"scraping_started"      # Début scraping d'une URL
"html_cleaned"          # HTML nettoyé (tailles, réduction%)
"scraping_completed"    # Fin scraping (changements?, durée)
"scraping_failed"       # Erreur (message, compteur)
"claude_cli_completed"  # Parsing Claude (durée, succès)
"events_updated"        # Events créés/updatés (count)
```

### ChangeLog
Table qui stocke l'historique des changements détectés:
```ruby
scraped_url_id
diff_html                  # Diff visuel HTML
changements_detectes       # Array de strings (résumé)
created_at
```

## Gestion erreurs

### Retry automatique
- ScrapingJob: 3 tentatives avec backoff exponentiel
- EventUpdateJob: 3 tentatives

### Compteur erreurs consécutives
```ruby
scraped_url.erreurs_consecutives += 1

if erreurs_consecutives >= 3
  # TODO: AlertEmailJob.perform_later (Story 3.6)
  # Alerte admin par email
end
```

### Statuts ScrapedUrl
```ruby
enum :statut_scraping, {
  actif: 0,    # Scraping actif
  inactif: 1,  # Désactivé manuellement
  erreur: 2    # En erreur (3+ échecs consécutifs)
}
```

## Performance

### Temps de traitement
- **Scraping simple (HTTParty):** ~2s
- **Scraping Playwright (Wix):** ~15s
- **Conversion Markdown:** ~0.1s
- **Parsing Claude:** ~30-40s
- **Total par URL (avec changements):** ~45-60s

### Parallélisation
- Solid Queue: multiple workers
- Jobs indépendants par URL
- Pas de limite concurrence (chaque URL isolée)

### Charge système
- Playwright: ~150 MB RAM par instance
- PostgreSQL: ~100 MB pour 200 sites (HTML + Markdown)
- Claude CLI: appels API (pas de charge serveur)

## Tests

### Test manuel d'une URL
```ruby
bin/rails runner "
url = ScrapedUrl.find(7)
ScrapingEngine.process(url)
url.reload
puts 'HTML: ' + (url.derniere_version_html.bytesize / 1024.0).round(2).to_s + ' KB'
puts 'Markdown: ' + (url.derniere_version_markdown.bytesize / 1024.0).round(2).to_s + ' KB'
puts 'Events: ' + Event.where(scraped_url_id: 7).count.to_s
"
```

### Preview admin
**URL:** `/admin/scraped_urls/:id/preview`

**Features:**
- 4 onglets interactifs
- Statistiques (tailles, réduction%)
- JSON events parsés
- Markdown envoyé à Claude
- Data-attributes extraits
- HTML brut

## Exemples réels

### Marc Silvestre (Wix)
```
URL: https://www.marcsilvestre.com/agenda-cours-stages-1
use_browser: true (Playwright requis)
HTML: 419 KB
Markdown: 5 KB
Réduction: 98.7%
Events détectés: 13
Temps total: ~50s
```

## Crawler de sites (branche exploration-site-prof)

### Vue d'ensemble

Le crawler permet de découvrir automatiquement les pages d'ateliers/stages sur le site d'un professeur, à partir d'une seule URL racine. Un LLM gratuit (via OpenRouter) classifie chaque page trouvée.

### Flux crawl

```
┌─────────────────────────────────────────────────────────────────────┐
│ Admin clique "Crawler le site" sur /admin/scraped_urls/:id         │
│ → SiteCrawlJob.perform_later(scraped_url_id, llm_model:)          │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ SiteCrawler.new(scraped_url, llm_model:).crawl!                    │
│                                                                     │
│  1. Créer SiteCrawl (statut: running)                              │
│  2. BFS récursif (queue + visited Set):                            │
│     │                                                               │
│     ├─> Fetch page (HTTParty par défaut)                           │
│     │   └─> Si JS-only détecté → fallback Playwright              │
│     │       (texte visible < 500 chars OU <noscript> JavaScript)   │
│     │                                                               │
│     ├─> HTML → Markdown (HtmlCleaner)                              │
│     │                                                               │
│     ├─> OpenRouter LLM → "oui" ou "non"                           │
│     │   (contient un atelier/stage avec date ?)                    │
│     │   └─> Retry 3x avec backoff 15/30/45s sur HTTP 429          │
│     │                                                               │
│     ├─> Créer CrawledPage (url, depth, hash, verdict)             │
│     │                                                               │
│     └─> Extraire liens même domaine → ajouter à queue             │
│                                                                     │
│  3. Pour chaque page "oui" :                                       │
│     ├─> Créer ScrapedUrl auto (si URL pas déjà en base)           │
│     ├─> Hériter use_browser du parent                              │
│     └─> Hériter professors du parent (ProfessorScrapedUrl)        │
│                                                                     │
│  4. Finaliser SiteCrawl (statut: completed, stats)                │
│                                                                     │
│  Limites : profondeur max 5, max 100 pages, même domaine          │
│  Rate limit : sleep 3s entre appels LLM                            │
└─────────────────────────────────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────┐
│ SiteCrawlDispatchJob (recurring, 4am)                              │
│                                                                     │
│  Pour chaque ScrapedUrl avec auto_recrawl=true :                   │
│  ├─> Fetch page racine, calculer hash                              │
│  ├─> Comparer avec hash du dernier crawl                           │
│  └─> Si différent → enqueue SiteCrawlJob                          │
└─────────────────────────────────────────────────────────────────────┘
```

### Composants

#### SiteCrawler (lib/site_crawler.rb)
- Algorithme BFS (Breadth-First Search)
- HTTParty par défaut, fallback Playwright si JS-only
- Détection JS-only : texte visible < 500 chars OU `<noscript>` contient "javascript"
- Extraction liens via Nokogiri (`a[href]`), normalisation URI, filtrage même domaine

#### OpenRouterClassifier (lib/open_router_classifier.rb)
- API OpenRouter (`/api/v1/chat/completions`)
- Prompt en français : "contient un atelier/stage avec date ? oui/non"
- Markdown tronqué à 10 000 chars
- Retry 3x avec backoff (15/30/45s) sur HTTP 429
- Modèle configurable (défaut : `google/gemma-3n-e4b-it:free`)

#### Models
- **SiteCrawl** : un crawl = une exécution (belongs_to :scraped_url, has_many :crawled_pages)
- **CrawledPage** : une page découverte (url, depth, content_hash, llm_verdict, http_status)

#### Jobs
- **SiteCrawlJob** : exécution async, retry 3x exponentiel, queue :scraping
- **SiteCrawlDispatchJob** : recurring 4am, vérifie hash racine pour auto-recrawl

### Admin UI Crawler
- Bouton "Crawler le site" sur `/admin/scraped_urls/:id` (dropdown modèle LLM)
- `/admin/site_crawls` : liste des crawls (statut, pages, oui/non, modèle)
- `/admin/site_crawls/:id` : détail pages crawlées (verdict ✅/❌/⚠️)
- `/admin/settings/edit` : modèle OpenRouter par défaut

### Performance réelle

| Site | Type | Pages | OUI | NON | Durée |
|------|------|-------|-----|-----|-------|
| Silvestre (Wix) | HTTParty | 12 | 6 | 6 | ~30s |
| Wilberforce (Wix) | HTTParty | 25 | 14 | 11 | ~4 min |

### Configuration

**Variables d'environnement :**
```bash
OPENROUTER_API_KEY=sk-or-v1-xxx    # Clé API OpenRouter
OPENROUTER_TIMEOUT=30               # Timeout appel LLM (secondes)
OPENROUTER_RATE_LIMIT_SLEEP=3       # Pause entre appels LLM
```

**Admin Settings :** `Setting.instance.openrouter_default_model` (dropdown dans /admin/settings)

---

## Architecture future (TODO)

### Améliorations prévues
- [ ] AlertEmailJob pour erreurs 3+ consécutives
- [ ] Dashboard admin avec graphiques scraping
- [ ] Cache LLM crawler (même URL + même hash → réutiliser verdict)
- [ ] Détection changement fine (hash par page, pas seulement racine)
- [ ] Support iCal/Google Calendar direct

## Diagramme de classes

```
ScrapedUrl
├── has_many :events
├── has_many :change_logs
├── has_many :professors (through professor_scraped_urls)
├── has_many :site_crawls
├── belongs_to :source_site_crawl (optional, pour auto-créées)
└── auto_recrawl (boolean)

SiteCrawl
├── belongs_to :scraped_url
├── has_many :crawled_pages
└── has_many :auto_created_scraped_urls (ScrapedUrl)

CrawledPage
└── belongs_to :site_crawl

Event
├── belongs_to :scraped_url
├── belongs_to :professor
└── has_many :event_sources

Professor
├── has_many :events
└── has_many :scraped_urls (through professor_scraped_urls)

ChangeLog
└── belongs_to :scraped_url

Setting (singleton)
├── claude_global_instructions
└── openrouter_default_model
```

## Ressources

- **Playwright:** https://playwright.dev/
- **ReverseMarkdown:** https://github.com/xijo/reverse_markdown
- **Claude AI:** https://claude.ai/
- **Solid Queue:** https://github.com/rails/solid_queue

---

**Dernière mise à jour:** 2026-04-07
**Version:** 2.0 (ajout crawler site + OpenRouter)
**Mainteneur:** Stop & Dance Team
