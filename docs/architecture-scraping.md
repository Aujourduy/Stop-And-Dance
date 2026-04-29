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
│  ├─> 4. RecurrenceExpander.expand (pour chaque event)             │
│  │    ├─> Si recurrence=null → pass-through (1 event)            │
│  │    ├─> Si recurrence.type=weekly → génère N events             │
│  │    │    (aujourd'hui → 31 août, 1 par semaine)                 │
│  │    ├─> Exclut excluded_dates + excluded_ranges                 │
│  │    └─> Si dates explicites → Claude les retourne déjà          │
│  │                                                                  │
│  └─> 5. Création/update Events en DB                              │
│       ├─> Pour chaque event (après expansion):                    │
│       │    • Parse dates (ISO 8601)                                │
│       │    • Calcule type_event par durée (<5h = atelier)         │
│       │    • Find_or_initialize_by (url + date + titre)           │
│       │    • Sauvegarde en DB                                      │
│       │                                                             │
│       └─> Log résultats (events Claude + events après expansion) │
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

### 8. RecurrenceExpander
**Rôle:** Expand les événements récurrents en dates individuelles
**Fichier:** `lib/recurrence_expander.rb`

**3 cas gérés :**

| Cas | Exemple | Comportement |
|-----|---------|-------------|
| Dates explicites | "12 avril, 26 avril, 10 mai" | Claude retourne N events séparés. Pass-through. |
| Récurrence weekly | "Tous les vendredis 19h30" | Claude retourne 1 template avec `recurrence`. Rails génère N events. |
| Exclusions | "sauf le 18 avril" / "vacances 15-30 juillet" | Dates/périodes retirées du calcul. |

**Période de génération :** aujourd'hui → 31 août (année en cours, ou suivante si on est après le 31 août)

**Champ `recurrence` dans le JSON Claude :**
```json
{
  "recurrence": {
    "type": "weekly",
    "day_of_week": "friday",
    "time_start": "19:30",
    "time_end": "21:30",
    "excluded_dates": ["2026-04-18"],
    "excluded_ranges": [{"from": "2026-07-15", "to": "2026-07-30"}]
  }
}
```

**Résultats réels :**
- Marc Silvestre : 13 events Claude → 32 après expansion (20 vendredis + 12 stages)
- Peter Wilberforce : 61 events Claude → 79 après expansion (19 mardis + dates explicites)

### 9. EventUpdateJob
**Queue:** `:scraping`
**Retry:** 3 tentatives
**Logique:**

1. Parse via Claude CLI
2. Expand récurrences (RecurrenceExpander)
3. **Clean slate** : supprime tous les events existants de cette ScrapedUrl
4. Recrée tous les events

**Pour chaque event (après expansion) :**
1. Skip si date manquante
2. Parse datetime → extrait date (date_debut_date) + heure (heure_debut, nullable)
3. Si heure = minuit (00:00) → heure_debut = nil (horaire non renseigné sur le site)
4. Calcule type_event :
   - Si horaire connu : durée < 5h → atelier, >= 5h → stage
   - Si horaire inconnu : 1 jour → atelier, multi-jours → stage
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
date_debut_date            # Date seule (ex: 2026-04-12)
date_fin_date              # Date seule (>= date_debut_date)
heure_debut                # Time nullable (nil = horaire non renseigné)
heure_fin                  # Time nullable
date_debut                 # DateTime legacy (sync auto via callback)
date_fin                   # DateTime legacy (sync auto via callback)
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

## Règles métier du scraping

### Re-parsing (clean slate)
À chaque re-scraping d'une URL, **tous les events existants sont supprimés** puis recréés. Pas d'accumulation, pas de doublons.

### Dates et horaires
- `date_debut_date` / `date_fin_date` : dates obligatoires
- `heure_debut` / `heure_fin` : nullable. Si le site ne mentionne pas l'horaire, on ne l'invente pas
- Le prompt Claude utilise minuit (00:00) pour signifier "horaire non renseigné"
- Affichage : "—" dans la card, "Horaires à confirmer" dans la modal

### Récurrences
- **Dates explicites** (ex: "12 avril, 26 avril") : Claude retourne N events séparés
- **Weekly** (ex: "tous les vendredis") : Claude retourne 1 template avec `recurrence.type=weekly`, Rails génère les dates (aujourd'hui → 31 août)
- **Exclusions** : `excluded_dates` (dates isolées) + `excluded_ranges` (périodes vacances)
- Seul `weekly` est supporté. Autres types → passthrough (1 event) + notification admin auto
- Events récurrents marqués `generated_from_recurrence=true`

### Déduplication
- **Cross-URL** : même prof + même date + même heure depuis 2 URLs → garde le plus complet
- **Intra-URL** : même prof + même date + même heure dans la même URL → **explicite gagne sur récurrent**
- Score de complétude : description, adresse, prix, tags pondérés
- Clean slate à chaque re-parsing (supprime events avant recréation)

### Tests automatisés QA
3 tâches rake disponibles :
- `scraping:dry_run` — vérifie fetch + markdown sans écrire en DB (~100s)
- `scraping:verify` — Claude compare screenshots vs events DB (match/partial/mismatch, ~3min)
- `scraping:missing` — Claude détecte events visibles sur le site mais absents de la DB (~1min)
- Détails : `docs/scraping-urls.md`

### Normalisation des titres
- Mots en MAJUSCULES (2+ lettres) → capitalize automatique
- Acronymes préservés : configurables dans Admin > Paramètres (défaut: CI, BMC, DJ, MC, NYC, USA)

### Synonymes type d'événement
Configurés dans le prompt Claude :
- "Vague", "Waves", "Jam" → atelier
- "Intensif", "Retraite", "Résidentiel" → stage

### Photos professeurs
- Stockage : `public/photos/professors/prof_X.jpg` (300×300px, crop auto MiniMagick)
- Priorité affichage dans cards : `event.photo_url` > `professor.avatar_url` > placeholder initiale
- Auto-download : Claude extrait `professor_photo_url` au parsing, téléchargé si prof sans photo
- Upload manuel : admin professors edit (file input + crop auto)
- Servi par Rails/Cloudflare (pas de dépendance Cloudinary)

### Héritage sur auto-crawl
Les ScrapedUrl auto-créées par le crawler héritent du parent :
- Flag `use_browser`
- Associations `ProfessorScrapedUrl`

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
- [ ] **Validation 2-IA contre hallucinations Claude** (voir section dédiée ci-dessous)

### Validation 2-IA contre hallucinations Claude

#### Problème observé

Claude CLI hallucine régulièrement sur les events extraits du markdown :

| Cas observé | Source markdown | Sortie Claude |
|---|---|---|
| **Garance Marseille** (avril 2026) | "Mardi 28 avril" sans heure | date `2026-04-27` (J-1) + heure `23:00:00` inventée |
| **Préfixes DJ** | "avec DJ Mike Polarny" | nom du prof = "DJ Mike Polarny" au lieu de "Mike Polarny" |
| **Dates vs jours de semaine** | "Mardi 28 avril" sans année | calendrier 2025 vs 2026 confondu → décalage J±1 |
| **Heures inventées** | aucune heure mentionnée | génère des heures plausibles type 19h-21h |

Mitigations actuelles (insuffisantes) :
- Prompt enrichi avec règles strictes (RÈGLE HORAIRES, RÈGLE DATES, RÈGLE NOMS)
- Filet de sécurité côté code : `EventUpdateJob#suspicious_hour?` nullifie heures < 7h ou ≥ 23h

→ **Ces mitigations ne couvrent pas tous les cas**. Une seconde IA validatrice donnerait un filet plus robuste.

#### Architecture cible : pipeline 2-IA

**État actuel (1 IA)** :
```
HTML → Markdown → [Claude CLI extraction] → JSON events → DB
                       ↑
                  (hallucinations possibles, non détectées)
```

**Cible (2 IA)** :
```
HTML → Markdown
   │
   ├─→ [IA 1: Claude CLI extraction] → JSON events brut
   │
   └─→ [IA 2: Validateur (modèle différent)] → audit
       Compare JSON proposé vs Markdown source :
       - Vérifie chaque date/heure citée existe textuellement dans le MD
       - Détecte heures inventées (absentes du MD)
       - Détecte décalages calendaires (jour de semaine ≠ date numérique)
       - Détecte préfixes parasites (DJ, Dr., M., Mme)
       - Vérifie cohérence noms profs vs descriptions

   ↓ Si IA 2 valide → JSON propre → DB
   ↓ Si IA 2 détecte anomalie → AdminNotification + flag review_required
```

#### Choix techniques

**IA 2 — Modèle différent de Claude pour diversité** :
- Option A : OpenRouter (modèles concurrents : Gemini, GPT-4, Llama, Mistral) — déjà utilisé pour `OpenRouterClassifier` du crawler
- Option B : Claude différent (Sonnet/Haiku/Opus) — moins fort en diversité
- Option C : Validation déterministe **sans IA** — regex/parsing strict (heures absentes du MD = warning)

**Reco** : **A + C combinés**
- C en premier filtre (rapide, gratuit, déterministe) — attrape les cas triviaux
- A en deuxième filtre (IA externe) — attrape les cas subtils

**Niveaux d'action sur détection** :
- 🟢 **Pass** : aucune anomalie détectée → save event
- 🟡 **Warning** : anomalie probable → save event mais flag `review_required: true` + AdminNotification
- 🔴 **Reject** : hallucination certaine (ex: date introuvable dans MD) → ne pas save, log error

**Coût estimé** : OpenRouter Gemini Flash ≈ 0.075$/M tokens input. Une validation = ~5k tokens (markdown + JSON) = ~0.0004$/event. À 100 events/scrape × 60 scrapes/jour = ~2.5$/mois. Acceptable.

#### Composants à créer

```
lib/
  event_validator.rb              # Service principal
  event_validators/
    deterministic_validator.rb    # Regex/parsing (filtre C)
    llm_validator.rb              # OpenRouter (filtre A)
```

**Intégration dans `EventUpdateJob`** :
```ruby
# Après fetch Claude, avant save
validation = EventValidator.audit(events_from_claude, markdown_source)

case validation.status
when :pass    then save_events(events_from_claude)
when :warning then save_events_with_flag(events_from_claude, validation.warnings)
when :reject  then notify_admin_and_skip(validation.errors)
end
```

**Modèle Event** : ajout colonne `review_required: boolean` + `validation_warnings: jsonb` pour tracer les anomalies détectées.

**UI Admin** : badge "À vérifier" sur les events flaggés dans `/admin/events`, filtre dédié.

#### Phasing d'implémentation

1. **Phase 1** : `DeterministicValidator` (filtre C uniquement) — détecte heures absentes du MD, dates incohérentes (jour de semaine), préfixes parasites. ~2h de dev. Couvre 80% des cas.
2. **Phase 2** : `LlmValidator` via OpenRouter — couverture des cas subtils. ~3h de dev.
3. **Phase 3** : UI admin pour review manuel des flags. ~2h de dev.

**Total : ~7h** sur 3 sprints.

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
