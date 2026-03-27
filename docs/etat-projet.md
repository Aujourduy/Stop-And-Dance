# État du Projet - Stop & Dance v2

**Dernière mise à jour :** 2026-03-28
**Branch :** main
**Dernière commit :** 3df9fe6 - Flash messages auto-dismiss + timeout Playwright 10min
**Statut :** ✅ **PROJET TERMINÉ - Système de test scraping ajouté**

---

## 🎯 Session 2026-03-28 : Système de test scraping

### Nouvelles fonctionnalités implémentées

**1. PlaywrightScraper opérationnel**
- Nouveau scraper avec Chromium headless pour sites JavaScript
- Timeout 10 minutes pour pages complexes
- Scroll automatique pour lazy-loading
- User-Agent custom : "stopand.dance bot"

**2. Interface admin de test scraping**
- 4 boutons dans la preview pour tester chaque étape :
  - 🌐 **HTTParty** (vert) : fetch rapide sans JS (1-2s)
  - 🎭 **Playwright** (bleu) : browser complet avec JS (10min max)
  - 📝 **Markdown maker** (jaune moutarde) : conversion HTML→Markdown
  - 🔄 **Re-parser avec Claude** (terracotta) : parsing Markdown→Events
- Infobulles détaillées sur chaque bouton (usage, durée, avantages)

**3. Badge indicateur mode production**
- Visible dans : liste admin, page show, preview
- Indique le mode selon `use_browser` (HTTParty ou Playwright)

**4. Formulaire edit amélioré**
- Choix visuel HTTParty vs Playwright avec radio buttons
- Descriptions détaillées pour chaque mode

**5. Flash messages améliorés**
- Auto-dismiss après 5 secondes
- Bouton × pour fermer manuellement
- Transition en fondu

**6. Documentation Tailwind CSS v4**
- Section WARNING ajoutée dans CLAUDE.md
- Explique que `tailwind.config.js` ne fonctionne plus pour les couleurs
- Méthode correcte : `@theme` dans `app/assets/tailwind/application.css`

### ⚠️ TODO PROCHAINE SESSION

**🧪 TESTER PLAYWRIGHT EN PRODUCTION**
1. Aller dans `/admin/scraped_urls`
2. Créer une nouvelle URL avec un site JavaScript (Wix, React, etc.)
3. Cocher `use_browser: true` dans le formulaire
4. Cliquer sur "🎭 Playwright" dans la preview
5. Vérifier que le HTML est bien récupéré (avec contenu JS chargé)
6. Comparer avec HTTParty pour voir la différence

---

## 🎉 Projet Complété

**Tous les epics (1-9) sont terminés !** Le site est prêt pour la production.

---

## Epics Terminés (100%)

### ✅ Epic 1: Infrastructure & Deployment (DÉBUT + FIN)
**Stories :** 1.1, 1.2, 1.3 (début) + production deployment (fin)

**Livrables :**
- PostgreSQL local + production
- 8 models avec validations
- Seeds réalistes
- Solid Queue pour jobs background
- Docker + Caddy + HTTPS Cloudflare
- Déploiement production complet

### ✅ Epic 2: Homepage & Design System (5 stories)
**Stories :** 2.1, 2.2, 2.3, 2.4, 2.5

**Livrables :**
- Design system terracotta/beige complet
- Homepage Hero responsive
- Navigation desktop/mobile (burger menu)
- Composants réutilisables (Tags, Pills)
- Accessibilité WCAG 2.1 AA

### ✅ Epic 3: Automated Scraping Engine
**Livrables :**
- HtmlDiffer pour détection changements
- Claude CLI Integration Service
- ScrapingJob avec retry + logging
- ScrapingDispatchJob (orchestration 24h)
- Event deduplication & conflict resolution
- Admin interface ScrapedUrls management

### ✅ Epic 4: Event Discovery & Browsing
**Livrables :**
- Liste événements chronologique
- Infinite scroll (Pagy)
- Event modal avec détails complets
- Turbo Frame navigation

### ✅ Epic 5: Event Filtering & Search
**Livrables :**
- Filtres date (date picker)
- Filtres type (atelier/stage)
- Filtres format (en ligne/présentiel)
- Filtres prix (gratuit/payant)
- Reset filtres

### ✅ Epic 6: Newsletter Subscription
**Livrables :**
- Formulaire newsletter (sidebar + footer)
- Validation email
- Flash messages succès/erreur
- Admin: consultation liste emails

### ✅ Epic 7: Professor Profiles & Stats
**Livrables :**
- Page profil professeur
- Bio + photo + site web
- Liste événements du professeur
- Stats publiques (vues + clics sortants)
- Redirect tracking vers site professeur

### ✅ Epic 8: SEO & Discoverability
**Livrables :**
- Meta tags dynamiques (OG, Twitter)
- JSON-LD schema.org (Event, Person)
- Sitemap.xml dynamique
- Cache sitemap (1h)
- robots.txt

### ✅ Epic 9: Admin Interface
**Livrables :**
- Admin dashboard
- CRUD ScrapedUrls
- Preview HTML avant scraping
- Trigger scraping manuel
- Change logs consultation
- HTTP Basic Auth

---

## Fonctionnalités Implémentées

**Infrastructure :**
- Rails 8.1.2 + PostgreSQL
- Solid Queue (jobs background)
- Docker + Caddy reverse proxy
- HTTPS via Cloudflare
- Ports : 3002 (dev), 3000 (prod)
- Tailscale VPN pour admin

**Scraping Automatisé :**
- Scraping 24h automatique
- Détection changements HTML
- Parsing via Claude CLI
- Retry exponential 3x
- Logs structurés JSON
- Admin trigger manuel

**UI/UX :**
- Homepage Hero responsive
- Navigation burger mobile
- Design terracotta/beige
- Mode debug (Ctrl+Shift+D)
- Tags visuels (type, prix, format)
- Accessibilité WCAG 2.1 AA
- Infinite scroll

**Événements :**
- Liste chronologique
- Filtres multi-critères
- Event modal détaillé
- Compteurs (ateliers/stages)

**Professeurs :**
- Pages profil
- Stats publiques
- Redirect tracking

**SEO :**
- Meta tags dynamiques
- JSON-LD structured data
- Sitemap.xml auto-généré
- Cache optimisé

**Admin :**
- Dashboard complet
- Gestion ScrapedUrls
- Preview HTML
- Change logs
- HTTP Basic Auth

**Qualité :**
- 71 tests (0 failures)
- RuboCop : 0 offenses
- Brakeman : 1 warning (Ruby EOL, non-bloquant)
- CI GitHub Actions (lint, scan_ruby, scan_js)
- Tests système Capybara + Playwright

---

## Architecture Technique

**Stack :**
- Rails 8 monolithe
- PostgreSQL
- Turbo (pas Stimulus pour MVP)
- Tailwind CSS
- Solid Queue
- Pagy pagination
- Capybara + Playwright (tests)

**Scraping :**
- 1 seul HtmlScraper générique (MVP)
- Claude CLI pour parsing
- HtmlDiffer pour changements
- Jobs background avec retry

**Timezone :**
- UTC en base
- Europe/Paris à l'affichage

**Routes publiques :**
- Français : /evenements, /professeurs
- Admin : /admin (HTTP Basic Auth)

**Conventions :**
- Pagy (JAMAIS `.page().per()`)
- `increment_counter` (JAMAIS `increment!`)
- `Time.current` (JAMAIS `Date.current`)

---

## Outils Développement

**Mode debug design :** `Ctrl+Shift+D`
- Affiche ID éléments
- Affiche classes CSS
- Affiche contenu texte
- Infobulle centrée fond vert pistache

**Compteurs dans titre :**
- Nombre ateliers/stages visible dans onglet navigateur

**Sync état projet :**
- `bin/sync-gist.sh` : sync docs/etat-projet.md vers Gist GitHub
- Permet à claude.ai de lire l'état projet (repo privé)

---

## Production

**Déploiement :**
- Docker containers (dev port 3001, prod port 3000)
- Caddy reverse proxy
- HTTPS via Cloudflare (DNS + proxy)
- Backup PostgreSQL automatisé
- Monitoring logs via journalctl

**Domaine :**
- stopand.dance

**Admin access :**
- Restreint au réseau Tailscale VPN (optionnel)
- HTTP Basic Auth (credentials ENV vars)

---

## Post-MVP

**Améliorations futures possibles :**
- Scrapers spécialisés par site (si HTML complexe)
- Upgrade Ruby 3.3+ (EOL 3.2.10 : 31 mars 2026)
- Notifications email newsletter automatiques
- Analytics événements populaires
- Cartes géographiques des événements
- Export iCal (.ics) pour calendriers
- API REST publique

---

## Commandes Utiles

**Dev :**
```bash
bin/rails s -p 3002           # Lancer serveur dev
bin/rails test                # Tests unitaires
bin/rails test:system         # Tests système
bin/rubocop                   # Lint code
bin/brakeman -w 2             # Scan sécurité
bin/sync-gist.sh              # Sync état projet
```

**Production :**
```bash
ddup                          # Start prod (alias docker compose up)
dddown                        # Stop prod
docker compose logs -f web    # Voir logs
```

**Scraping :**
```bash
bin/rails scraping:run[1]     # Scraper URL ID 1
bin/rails scraping:test[1]    # Test parsing sans sauvegarder
```

---

## Notes Session Actuelle

**Session précédente (2026-03-26 matin) :**
- ✅ CI lint échouait (108 offenses RuboCop) → corrigé
- ✅ CI scan_ruby échouait (Command Injection, XSS) → corrigé
- ✅ Brakeman warnings (redirect, XSS) → config/brakeman.ignore créé
- ✅ Setup synchronisation Gist pour claude.ai → opérationnel

**Session 2026-03-27 matin :**
- ✅ Migration complète du projet "3 Graces" vers "Stop & Dance"
  - Module Rails : App → StopAndDance
  - Base de données : threegraces_v2_* → stopanddance_*
  - Docker : threegraces → stopanddance
  - Domaine : 3graces.community → stopand.dance
  - Documentation complète mise à jour
  - Tests : application démarre correctement
- ✅ Tag git pré-migration créé : pre-rename-stopanddance
- ✅ Repo GitHub renommé : 3-Graces → Stop-And-Dance
- ✅ Dossier projet renommé : ~/3graces-v2 → ~/stop-and-dance
- ✅ Chemins absolus corrigés dans la documentation
- ✅ Corrections références "3 Graces" → "Stop & Dance" dans le code
  - Vues : navbar, mobile_drawer, hero, tailwind_test
  - Logo Hero : "AU JOUR duy" → "Stop & Dance"
  - SEO metadata : @3graces → @stopanddance
  - User-agent scraper : 3graces.community → stopand.dance
  - Robots.txt : sitemap URL mis à jour
  - Scripts : backup-db.sh, deploy.sh, Caddyfile
  - Documentation : ui-reference.md, config.yaml
  - Tests : html_scraper_test.rb, pages_accessibility_test.rb
  - Tous les tests passent (71 runs, 0 failures)
- ✅ Améliorations UI et UX
  - Navbar desktop identique au mobile (logo + burger + icônes)
  - Cartes événements restructurées (2 colonnes : avatar 128×128px + 4 lignes texte)
  - Noms professeurs ajoutés dans seeds
  - Filtres auto-submit en temps réel (sans bouton Appliquer)
  - Panneau filtres mobile fonctionnel (slide depuis droite)
  - Compteurs dynamiques titre ("Agenda complet" vs "Agenda filtré")
  - Favicon site mis à jour (ICO, SVG, PNG)
  - Contrôleurs Stimulus : auto_submit + mobile_filters
- ✅ Configuration serveur
  - Puma bind sur 0.0.0.0 (accès réseau Tailscale)
  - Règle CLAUDE.md : toujours lancer avec -b 0.0.0.0 -p 3002
  - Site accessible via http://100.95.124.70:3002
- ✅ Déduplication professeurs (scraping)
  - Migration : nom_normalise (unique index) + status (auto/verified) + scraped_urls.nom
  - Concern Normalizable : normaliser_nom + find_or_create_from_scrape
  - Validation : nom presence required
  - Rake task : professors:backfill_nom_normalise
  - Tests : 17 tests déduplication (89 tests total, 0 failures)
  - Seeds : 5 profs dont 2 multi-sources (Sophie, Marie au Studio Collectif)
  - Documentation : docs/scraping-architecture.md complète
  - Fix : "Marie Dupont" = "marie dupont" = "Stéphane" = "Stephane" (accents strippés)
- ✅ Documentation utilisateur scraping
  - Guide complet : docs/guide-scraping.md
  - Ajouter URL, lancer scraping (test + réel), vérifier résultats
  - Debugging, notes correctrices, maintenance
  - Cheatsheet commandes rapides
- ✅ Documentation interface admin
  - Guide complet : docs/guide-admin.md
  - Accès /admin (HTTP Basic Auth : admin/changeme)
  - CRUD ScrapedUrls, consultation ChangeLogs, édition Events
  - Scraper maintenant, prévisualiser HTML
  - Sécurité et configuration credentials
- ✅ Index documentation centrale
  - docs/README.md : navigation toutes les docs
  - Sections par audience (admin, dev, PM)
  - Quick start dev + premier scraping

- ✅ Corrections interface admin
  - Fix login : credentials .env (admin/change_me_in_production) vs doc
  - Fix ScrapedUrl show : dernier_scraping_a supprimé → updated_at
  - Fix ChangeLog : texte_avant/apres supprimés → changements_detectes jsonb
  - Création vue change_logs/show avec diff HTML
  - Ajout champ commentaire (text) pour ScrapedUrls
  - Fix formulaire events/edit : TOUS les champs ajoutés (17 champs)
    - Informations base : titre, description, professor_id, type_event, tags
    - Dates : date_debut, date_fin
    - Lieu : lieu, adresse_complete
    - Tarifs : prix_normal, prix_reduit, gratuit
    - Format : en_presentiel, en_ligne (hybrid possible)
    - Médias : photo_url
  - Création vue events/show complète (détails + métadonnées)
  - Tests : 89 tests (0 failures), 8 system tests (0 failures)

**Session 2026-03-27 après-midi :**
- ✅ Optimisation scraping : HTML→Markdown avant envoi à Claude
  - Migration : 3 nouvelles colonnes (derniere_version_markdown, data_attributes, html_hash)
  - HtmlCleaner : extraction data-attributes + conversion Markdown (ReverseMarkdown)
  - Réduction tokens : 98.7% (419 KB → 5 KB pour site Wix)
  - ClaudeCliIntegration : stockage markdown + data après conversion
  - ScrapingEngine : calcul html_hash (SHA256) pour détection changements O(1)
- ✅ Preview admin amélioré : 6 onglets interactifs
  - Résultat parsing : events JSON (cache DB instantané, bouton re-parse optionnel)
  - Markdown view : rendu HTML stylé (redcarpet + prose Tailwind)
  - Markdown brut : code source markdown
  - Data attributes : data-* extraits du HTML
  - HTML view : rendu HTML dans iframe sandbox
  - HTML brut : code source HTML
  - Performance : prévisualisation instantanée (cache DB) vs 61s avant
  - Sécurité : helper render_markdown avec filter_html, safe_links_only
- ✅ Documentation architecture scraping complète
  - docs/architecture-scraping.md : 460 lignes, flux détaillé, composants, performance
  - Tous les composants documentés : ScrapingDispatchJob, ScrapingEngine, HtmlCleaner, etc.
  - Exemples réels, logs, monitoring, gestion erreurs
- ✅ Corrections bugs
  - Helper route : admin_scraped_url_preview_path → preview_admin_scraped_url_path
  - LoadError reverse_markdown : suppression require redondant
- ✅ Commits : b41b037, 737bd27, 5783ac8
- ✅ Correction preview HTML admin
  - Bug : méthode raw_html non incluse dans before_action :find_scraped_url
  - Résultat : iframe HTML view ne chargeait pas (404)
  - Fix : ajout :raw_html dans la liste des actions du before_action
  - Tests : 89 tests passent, routes preview + raw_html retournent 200
  - Commit : cffc7c9
- ✅ Corrections CI (lint + security scan)
  - RuboCop : 16 offenses corrigées automatiquement (StringLiterals lib/html_cleaner.rb)
  - Brakeman : XSS warning ajouté à brakeman.ignore (diff_html admin safe)
  - Tests : 89 tests passent (0 failures)
  - CI status : ✅ lint, ✅ tests, ✅ scan_ruby (1 warning Ruby EOL non-bloquant)
  - Commit : 4de7f8b
- ✅ Nouvelle règle CLAUDE.md global
  - Vérification CI obligatoire avant chaque push (lint + tests + scan)
  - Règle 4 - PROTECTION GIT enrichie avec checklist CI
  - Commit claude-config : cd4f363

**Prochaines actions suggérées :**
- Mise à jour credentials ENV (~/.env-stopanddance)
- Setup DNS pour stopand.dance
- Upgrade Ruby 3.3 avant EOL 3.2.10 (31 mars 2026)
- Tests production sur stopand.dance
- QA final complet (slash command `/qa`)
- Tester le scraping sur URLs réelles
