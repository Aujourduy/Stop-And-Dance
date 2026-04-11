# Scraping URLs — Dry-run et rapport

## Tâche `scraping:dry_run`

Itère sur toutes les `ScrapedUrl` avec `statut_scraping: "actif"`, exécute le pipeline de scraping **sans écrire en base de données**, et affiche un rapport ✅/❌ par URL.

### Lancer la tâche

```bash
bin/rails scraping:dry_run
```

**Note importante :** Le modèle dans ce projet est `ScrapedUrl` (pas `UrlSource`). Le flag `use_browser` détermine si Playwright ou HTTParty est utilisé pour le fetch.

## Pipeline exécuté

1. **Fetch HTML** — via `Scrapers::PlaywrightScraper` si `use_browser=true`, sinon `Scrapers::HtmlScraper`
2. **Nettoyage + conversion Markdown** — via `HtmlCleaner.clean_and_convert`
3. **Validation** — Markdown doit faire au moins 100 bytes (sinon JS-only détecté)

⚠️ Le dry-run **ne fait PAS** d'appel Claude CLI (trop lent pour un rapport batch). Il s'arrête après la conversion Markdown.

## Aucune écriture en DB

- Pas de création/mise à jour d'`Event`
- Pas de touche aux colonnes `derniere_version_html`, `derniere_version_markdown`, `data_attributes`, `html_hash`
- Les `Professor` ne sont pas modifiés non plus

Les tests vérifient explicitement ces invariants (`test "run_one does not create events"`, `test "run_one does not touch scraped_url html fields"`).

## Format du rapport

### En-tête

```
======================================================================
SCRAPING DRY RUN REPORT
======================================================================
Total URLs: 26
✅ Success: 18
❌ Failed:  8
======================================================================
```

### Lignes par URL

**Succès :**
```
✅ #7 site de Marc Silvestre
   html=419532B md=5421B
```

**Échec :**
```
❌ #53 Peter Wilberforce - Body Voice Being
   ERROR: Fetch failed: Connection timeout
```

### Champs retournés par `ScrapingDryRun.run_one(scraped_url)`

```ruby
{
  url_id: 7,                              # ID de la ScrapedUrl
  url: "https://www.example.com/agenda",  # URL source
  nom: "site de Marc Silvestre",          # Label descriptif
  success: true,                          # true si pipeline OK
  error: nil,                             # Message d'erreur si échec
  html_size: 419532,                      # Bytes HTML fetché
  markdown_size: 5421                     # Bytes Markdown après nettoyage
}
```

## Types d'erreurs possibles

| Erreur | Cause | Exemple |
|--------|-------|---------|
| `Fetch failed: <message>` | Erreur HTTP (timeout, 404, robots.txt) | `Fetch failed: Connection refused` |
| `Empty markdown after cleaning` | Contenu JS-only (React SPA, Wix sans fallback) | `Empty markdown after cleaning (42 bytes)` |
| `Exception: <class>: <message>` | Exception Ruby non gérée | `Exception: StandardError: Network down` |

## Tests Minitest

**Fichier :** `test/tasks/scraping_dry_run_test.rb`

**Fixtures HTML** (`test/fixtures/files/scraping/`) :
- `static_site.html` — site HTML statique classique avec `<article>` et événements
- `wix_site.html` — site Wix avec contenu dans le body (non-JS-only)
- `react_empty.html` — SPA React avec `<div id="root">` vide et `<noscript>`

**Couverture :**
- ✅ Succès sur site statique (11 tests au total)
- ✅ Succès sur Wix avec contenu
- ❌ Échec sur React SPA (markdown vide)
- ❌ Capture erreur fetch
- ❌ Capture exception Ruby
- ✅ Utilise Playwright si `use_browser=true`
- ✅ Utilise HtmlScraper si `use_browser=false`
- ✅ `run_all` retourne les résultats de toutes les URLs actives (ignore `pause`)
- ✅ Pas de création d'`Event`
- ✅ Pas de modification des champs HTML de `ScrapedUrl`
- ✅ `print_report` affiche en-tête + lignes ✅/❌ + message d'erreur

**Lancer les tests :**

```bash
bin/rails test test/tasks/scraping_dry_run_test.rb
```

## Cas d'usage

- **Audit régulier** : vérifier qu'aucune URL n'est cassée (changement de site, timeout)
- **Avant un déploiement** : s'assurer que le pipeline fonctionne end-to-end sur toutes les sources
- **Debug** : identifier rapidement les URLs qui nécessitent Playwright (JS-only) vs HTTParty
