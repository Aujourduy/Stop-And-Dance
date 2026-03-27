# État du Projet - Stop & Dance v2

**Dernière mise à jour :** 2026-03-27
**Branch :** main
**Dernière commit :** (en cours - migration vers Stop & Dance)
**Statut :** ✅ **PROJET TERMINÉ - TOUS LES EPICS COMPLÉTÉS + MIGRATION EN COURS**

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

**Session actuelle (2026-03-27) :**
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

**Prochaines actions suggérées :**
- Mise à jour credentials ENV (~/.env-stopanddance)
- Setup DNS pour stopand.dance
- Upgrade Ruby 3.3 avant EOL 3.2.10 (31 mars 2026)
- Tests production sur stopand.dance
- QA final complet (slash command `/qa`)
- Documentation utilisateur (guide admin)
