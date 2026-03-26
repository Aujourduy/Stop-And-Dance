# État du Projet - 3 Graces v2

**Dernière mise à jour :** 2026-03-26 18:00
**Branch :** main
**Dernière commit :** db95223 - "fix: Corrige tous les problèmes CI (lint, sécurité)"

---

## Epics Terminés

### ✅ Epic 1: Infrastructure & Deployment (3 stories)
- Story 1.1: Database Schema, Models & PostgreSQL Setup
- Story 1.2: Realistic Seed Data for UI Development
- Story 1.3: Application Configuration (Environment, Jobs, Timezone)

**Livrables :**
- PostgreSQL local configuré (user dang, peer auth)
- 8 models avec validations (Event, Professor, ScrapedUrl, Newsletter, EventSource, ChangeLog, Setting, SeedMetadata)
- Seeds réalistes (4 professeurs, 15+ événements ateliers/stages)
- Solid Queue configuré pour jobs background
- Timezone UTC en base, Europe/Paris à l'affichage

### ✅ Epic 2: Homepage & Design System (5 stories)
- Story 2.1: Tailwind Design System Configuration
- Story 2.2: Reusable Tag/Pill Component
- Story 2.3: PagesController & Hero Homepage
- Story 2.4: Responsive Navigation (Desktop & Mobile)
- Story 2.5: WCAG 2.1 AA Compliance & Accessibility

**Livrables :**
- Design system terracotta/beige (couleurs personnalisées Tailwind)
- Homepage avec Hero section responsive
- Navigation desktop/mobile (burger menu)
- Composant Tag réutilisable (ateliers, stages, gratuit, en ligne)
- Accessibilité WCAG 2.1 AA (aria-labels, focus states, skip links)

---

## Epic en Cours

**Epic 3: Automated Scraping Engine** (0/6 stories)

**Prochaine story :** Story 3.1 - HtmlDiffer Service for Change Detection

**Stories restantes :**
1. Story 3.1: HtmlDiffer Service for Change Detection
2. Story 3.2: Claude CLI Integration Service
3. Story 3.3: ScrapingJob with Retry & Logging
4. Story 3.4: Admin Interface for ScrapedUrls Management
5. Story 3.5: ScrapingDispatchJob (Scheduled Orchestrator)
6. Story 3.6: Event Deduplication & Conflict Resolution

---

## Fonctionnalités Implémentées

**Infrastructure :**
- Rails 8.1.2 + PostgreSQL local (dev port 3002)
- Solid Queue (jobs background)
- Pagy pagination
- Seeds data réalistes

**UI/UX :**
- Homepage Hero section responsive
- Navigation burger mobile
- Design system terracotta/beige
- Mode debug design (Ctrl+Shift+D) : affiche ID, classes CSS, contenu texte
- Tags visuels (ateliers, stages, gratuit, en ligne)
- Accessibilité WCAG 2.1 AA

**Backend :**
- 8 models avec validations
- 6 controllers (ApplicationController + 5 métier)
- 10 routes configurées (français pour public : /evenements, /professeurs)
- Timezone UTC/Europe/Paris
- Conventions : Pagy, increment_counter, Time.current

**Qualité :**
- 71 tests (0 failures)
- RuboCop : 0 offenses
- Brakeman : 1 warning (Ruby EOL, non-bloquant)
- CI GitHub Actions (lint, scan_ruby, scan_js)

---

## Problèmes Connus

**Résolus aujourd'hui :**
- ✅ CI lint échouait (108 offenses RuboCop) → corrigé
- ✅ CI scan_ruby échouait (Command Injection, XSS) → corrigé
- ✅ Brakeman warnings (redirect, XSS) → config/brakeman.ignore créé

**À surveiller :**
- Ruby 3.2.10 EOL le 31 mars 2026 (dans 5 jours) → upgrade futur

---

## Décisions Techniques Clés

**Architecture :**
- Rails 8 monolithe (pas de SPA)
- Turbo pour navigation (pas Hotwire Stimulus pour MVP)
- Scraping MVP : 1 seul HtmlScraper générique (pas de scrapers spécialisés)
- Timezone : UTC en base, Europe/Paris affichage

**Conventions :**
- Pagination : Pagy uniquement (JAMAIS `.page().per()`)
- Compteurs : `increment_counter` (JAMAIS `increment!`)
- Scopes temps : `Time.current` (JAMAIS `Date.current`)
- Routes publiques : français (/evenements, /professeurs)
- Tests système : Capybara + Playwright local (Chromium headless)

**Outils dev :**
- Mode debug design : Ctrl+Shift+D (affiche ID, classes, contenu)
- Compteurs ateliers/stages dans titre page (visible dans onglet)

---

## Prochaines Étapes

**Immédiat (Epic 3) :**
1. Story 3.1: HtmlDiffer Service for Change Detection
2. Story 3.2: Claude CLI Integration Service
3. Story 3.3: ScrapingJob with Retry & Logging
4. Story 3.4: Admin Interface for ScrapedUrls Management
5. Story 3.5: ScrapingDispatchJob (Scheduled Orchestrator)
6. Story 3.6: Event Deduplication & Conflict Resolution

**Après Epic 3 :**
- Epic 4: Events Listing & Search
- Epic 5: Event Modal & Professor Profile
- Epic 6: SEO & Sitemap
- Epic 7: Admin Change Logs & Analytics
- Epic 8: Error Handling & Monitoring
- Epic 9: Production Deployment (Docker, Caddy, Cloudflare)

**Notes :**
- Epic 1 FIN (Docker/prod) sera fait en dernier (après Epic 9)
- QA automatisé à lancer après chaque Epic (slash command `/qa`)
