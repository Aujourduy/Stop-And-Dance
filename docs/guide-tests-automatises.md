# Guide Tests Automatisés — Stop & Dance

## Vue d'ensemble

Le projet dispose de 6 niveaux de tests automatisés, du plus basique au plus intelligent :

| Niveau | Commande | IA ? | Durée | Ce que ça vérifie |
|--------|----------|------|-------|-------------------|
| 0 | `bin/rails test` | Non | ~2s | Models, controllers, services, jobs |
| 1 | `bin/rails scraping:dry_run` | Non | ~100s | Pipeline fetch + markdown sur toutes les URLs |
| 2a | `node script/ux-audit.js` | Non | ~30s | UI/UX headless (Playwright) : clics, saisies, nav, SEO |
| 2b | `bin/rails runner script/data-sanity.rb` | Non | ~2s | Sanity sémantique des données scrapées |
| 3 | `bin/rails scraping:verify` | Oui (Claude) | ~3min | Events DB correspondent au site |
| 4 | `bin/rails scraping:missing` | Oui (Claude) | ~1min | Events sur le site absents de la DB |

**Ordre recommandé :** 0 → 1 → 2a → 2b → 3 → 4

---

## Niveau 0 : Tests unitaires Minitest

```bash
bin/rails test
```

**110 tests** qui vérifient :

- **Models** : validations, associations, scopes (Event, Professor, ScrapedUrl, etc.)
- **RecurrenceExpander** : weekly, exclusions dates/ranges, noms français/anglais, start/end date, wrap année
- **ScrapingDryRun** : 3 types de sites (statique, Wix, React SPA), pas d'écriture DB, choix scraper
- **Controllers** : admin (auth, CRUD), public (events, professors)

**Résultat attendu :** 110 runs, 0 failures, 0 errors

---

## Niveau 1 : Dry-run scraping (sans IA)

```bash
bin/rails scraping:dry_run
```

**Ce que ça fait :** Pour chaque URL active, tente de télécharger la page (HTTParty ou Playwright selon `use_browser`) et convertir le HTML en Markdown. **Ne touche pas la base de données.**

**Ce que ça détecte :**
- Site en panne ou URL cassée
- Site JS-only dont on ne récupère pas le contenu
- Timeout, robots.txt bloquant
- Contenu trop petit (< 300 bytes de Markdown)

**Rapport :** affiché dans le terminal avec ✅/❌ par URL, durée, taille HTML/Markdown

**Vérification DB intacte :**
```bash
bin/rails runner "
before = Event.count
ScrapingDryRun.run_all
puts 'OK' if Event.count == before
"
```

### Résultat type
```
Total URLs:     27
✅ Success:     20
❌ Failed:      7
Total duration: 102.1s
```

### Bugs trouvés grâce à ce test
- 6 URLs example.com passaient à tort (markdown 169 bytes) → seuil relevé de 100B à 300B

---

## Niveau 2 : Verify (IA compare events DB vs site)

```bash
bin/rails scraping:verify
```

**Ce que ça fait :**
1. Prend un screenshot Playwright full-page de chaque site
2. Récupère les events futurs en DB pour cette URL
3. Envoie screenshot + events JSON à Claude CLI
4. Claude compare et retourne : `match` / `partial` / `mismatch`

**Ce que ça détecte :**
- Events en base qui ne correspondent pas au site (titres, dates, prix, lieux incorrects)
- Events mal parsés par Claude lors du scraping
- Pages dont le contenu a changé depuis le dernier scraping

**Rapport :** `tmp/scraping_verify_report.md`

**Status possibles :**

| Status | Signification |
|--------|---------------|
| ✅ match | Events DB correspondent au screenshot |
| ⚠️ partial | Correspondance partielle (résolution screenshot, noms différents) |
| ❌ mismatch | Events DB ne correspondent pas au site |
| 💀 error | Screenshot échoué ou erreur Claude |
| ⏭️ skip | URL sans events futurs en DB |

### Bugs trouvés grâce à ce test

| Bug | Impact | Correction |
|-----|--------|------------|
| 18 events en doublon (blog #86 vs cours #9, même prof + même date) | Doublons visibles sur l'agenda | Déduplication cross-URL implémentée |
| Marc 12 juin : event récurrent "Vagues" + event explicite "Studio Noces" en double | 2 events au lieu d'1 | Déduplication intra-URL (explicite > récurrent) |
| Event #94 : horaire de fin non capturé (15h-18h → seulement 15h) | Horaire incomplet | Identifié, prompt à améliorer |

### Limites
- ~15-20s par URL (screenshot + appel Claude CLI)
- La résolution du screenshot peut limiter la vérification détaillée
- Claude peut retourner "partial" quand les events sont corrects mais difficilement lisibles

---

## Niveau 3 : Missing (IA détecte events absents de la DB)

```bash
bin/rails scraping:missing
```

**Ce que ça fait :** L'inverse du verify.
1. Screenshot Playwright de chaque URL (uniquement celles avec events futurs)
2. Envoie screenshot + liste des events DB à Claude CLI
3. Claude identifie les events **visibles sur le site qu'on n'a PAS en base**
4. Comparaison par **DATE** (pas par titre) — même prof + même date = couvert

**Ce que ça détecte :**
- Events qu'on a oublié de scraper
- Nouveaux events ajoutés par le prof depuis le dernier scraping
- Contenu JS-only non récupéré par HTTParty

**Rapport :** `tmp/scraping_missing_report.md`

### Bugs trouvés grâce à ce test

| Bug | Impact | Correction |
|-----|--------|------------|
| Section stages Peter Wilberforce en JS-only non récupérée par HTTParty | Stages visibles sur le site mais absents de la DB | URL #9 passée en `use_browser: true` (Playwright) |

### Limites
- **Faux positifs possibles** — Claude peut halluciner des dates/noms sur des screenshots complexes (QR codes, images, texte petit). Toujours vérifier manuellement les events signalés.
- Ne s'exécute que sur les URLs avec events futurs en DB
- ~15s par URL

---

## Niveau 2a : UX headless Playwright

```bash
node script/ux-audit.js
```

Serveur Rails requis sur `:3002`. **49 tests** qui vérifient :

- **Mobile** (viewport 390x844) : pas de scroll horizontal sur 5 pages
- **Navigation** : burger → drawer, clic "Agenda" navigue, Escape ferme
- **Homepage** : hero, clic AGENDA → /evenements, saisie newsletter
- **Agenda** : titre, jours français, badges DaisyUI, mention "Gratuit"
- **Filtres** : recherche `q` (paris/xxx/silvestre/reset), checkboxes gratuit/stage/en_ligne, champ lieu (via request sniffing)
- **Modal** : clic carte → turbo-frame rempli, bouton × navigue, clic overlay ferme
- **Infinite scroll** : 30 → 60 events
- **Prof/Stats** : nom affiché, clic "Voir stats" → /stats
- **Footer + SEO** : liens 200, meta description, 1 h1, sitemap.xml

**Résultat attendu :** 49/49 passés.

### Bug trouvé grâce à ce test
`app/javascript/controllers/modal_controller.js` manquant — les vues utilisaient `data-controller="modal"` sans Stimulus controller associé → clic overlay inerte. Corrigé 2026-04-19.

---

## Niveau 2b : Data sanity sémantique

```bash
bin/rails runner script/data-sanity.rb
```

Complète les tests syntaxiques (ça existe, ça répond 200) par un **contrôle du sens métier** des données scrapées par l'IA. 7 contrôles :

| # | Contrôle | Signal |
|---|----------|--------|
| 1 | Noms composites (`" et "`, `" & "`) | fail — parsing raté |
| 2 | Noms > 40 caractères | warn |
| 3 | Profs orphelins (0 events, 0 URLs) | warn — reliquats |
| 4 | Attribution prof.site_web ≠ scraped_url host | warn — sampling requis |
| 5 | Un prof concentre > 90% des events d'une URL ≠ owner | fail |
| 6 | Events liés à un prof non listé dans scraped_url.professors | fail |
| 7 | Sampling 3 events aléatoires | affichage pour vérif manuelle |

**Résultat attendu :** 0 fail. Les warnings sont acceptables s'ils sont expliqués (ex. duo Marc+Peter).

### Bug trouvé grâce à ce test
Event "Paris - Le Corps De La Danse" attribué à Marc alors que scrapé depuis le site de Peter. `data-sanity` aurait détecté via **profs composites** (`#67 "Marc Silvestre et Peter Wilberforce"`) + **distribution déséquilibrée** (54 events Marc sur bodyvoiceandbeing vs 10 pour Peter owner). Corrigé 2026-04-19 (`ScrapedUrl#owner_professor`).

---

## Compléments : Rubocop + Brakeman

```bash
bin/rubocop          # Lint code (0 offenses attendu)
bin/brakeman --no-progress  # Scan sécurité (1 weak warning connu, faux positif)
```

---

## Quand lancer les tests ?

| Situation | Tests à lancer |
|-----------|---------------|
| Après modification du code | `bin/rails test` |
| Avant un commit | `bin/rails test` + `bin/rubocop` |
| Après modification UI/vue/JS | `node script/ux-audit.js` |
| Après ajout d'une nouvelle URL | `scraping:dry_run` |
| Après un scraping complet | `data-sanity` + `scraping:verify` + `scraping:missing` |
| Après re-parsing Claude (EventUpdateJob) | `data-sanity` |
| Debug : events manquants | `scraping:missing` |
| Debug : events incorrects ou mal attribués | `data-sanity` puis `scraping:verify` |
| Audit régulier (hebdo) | Les 6 niveaux dans l'ordre |

---

## Historique des corrections grâce aux tests auto

| Date | Bug trouvé | Test | Correction |
|------|-----------|------|------------|
| 2026-04-11 | 6 URLs example.com faux succès | `dry_run` | Seuil markdown 100B → 300B |
| 2026-04-13 | 18 doublons cross-URL (blog #86 vs cours #9) | `verify` | Dédup cross-URL (même prof + date + heure) |
| 2026-04-14 | Doublon intra-URL Marc 12 juin (récurrent + explicite) | `verify` | Dédup intra-URL, flag `generated_from_recurrence` |
| 2026-04-14 | Section stages JS-only Peter non récupérée | `missing` | URL #9 → `use_browser: true` |
| 2026-04-14 | Event #94 horaire de fin manquant | `verify` | Identifié (prompt à améliorer) |
| 2026-04-19 | `modal_controller.js` manquant → clic overlay modal inerte | `ux-audit` | Création du controller Stimulus |
| 2026-04-19 | Event attribué à Marc au lieu de Peter sur URL multi-profs | analyse manuelle (aurait été vu par `data-sanity` rétroactivement) | `ScrapedUrl#owner_professor` + création de `data-sanity.rb` |

---

**Dernière mise à jour :** 2026-04-19
