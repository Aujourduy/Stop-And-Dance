# Epic Stories Review - Corrections Appliquées

**Date:** 25 mars 2026
**Total corrections:** 15+ modifications transversales

---

## EPIC 1: Database Schema & Core Models

### ✅ Story 1.1: Events Table
- **Ajout:** colonne `photo_url (string nullable)` pour URLs externes scrapées par Claude CLI
- **Conservation:** définition slug (colonne + callback) - suppression doublon Epic 8

### ✅ Story 1.1: Professors Table
- **Modification:** `bio (text nullable)` au lieu de required
- **Raison:** professeurs scrapés peuvent ne pas avoir de bio initialement

---

## EPIC 3: Automated Scraping Engine

### ✅ Story 3.3: Specialized Scrapers → Supprimée (MVP)
- **Avant:** 3 scrapers spécialisés (GoogleCalendar, Helloasso, Billetweb)
- **Après:** Placeholder pour post-MVP, tout via HtmlScraper + Claude CLI
- **Raison:** notes_correctrices permettent parsing platform-specific sans duplication

### ✅ Story 3.2: HtmlScraper - Claude CLI Syntax
- **Correction commande:**
  ```ruby
  # ❌ AVANT (incorrect):
  claude --dangerously-skip-permissions < prompt_file

  # ✅ APRÈS (correct):
  cat prompt_file | claude -p - --dangerously-skip-permissions
  ```
- **Ajout:** commentaire validation syntax à l'implémentation

### ✅ Story 3.4: Solid Queue Cron - ScrapingDispatchJob
- **Avant:** Tentative passage array args à recurring_tasks (impossible)
- **Après:** Création `ScrapingDispatchJob` qui dispatch vers `ScrapingJob` individuels
  ```ruby
  class ScrapingDispatchJob < ApplicationJob
    queue_as :scraping
    def perform
      ScrapedUrl.where(statut_scraping: 'actif').find_each do |scraped_url|
        ScrapingJob.perform_later(scraped_url.id)
      end
    end
  end
  ```

### ✅ Story 3.1: ScrapingEngine.detect_scraper
- **Modification:** méthode `detect_scraper` public (au lieu de private)
- **Raison:** réutilisation dans Admin::ScrapedUrlsController (Epic 9)

---

## EPIC 4: Event Discovery & Browsing

### ✅ Story 4.1: EventsController - Root Route
- **Suppression:** redirect root → /evenements
- **Raison:** conflit avec Story 2.3 (homepage statique)
- **Ajout:** commentaire `# Root route defined in Story 2.3 (homepage)`

### ✅ Story 4.1: EventsController - Pagy Syntax
- **Correction:**
  ```ruby
  # ❌ AVANT (Kaminari):
  @events = Event.futurs.order(:date_debut).page(params[:page]).per(30)

  # ✅ APRÈS (Pagy):
  @pagy, @events = pagy(
    Event.futurs.includes(:professor).order(:date_debut),
    items: 30
  )
  ```

### ✅ Story 4.3: Event Detail Page - SEO Comment
- **Ajout:** `# set_event_metadata defined in Epic 8 (SeoMetadata concern)`

---

## EPIC 5: Event Filtering & Search

### ✅ Story 5.3: FilteredEventsController - Algolia Geo Search Comment
- **Ajout commentaire pour filtre lieu:**
  ```ruby
  # Geographic filter (basic MVP - exact match)
  # Post-MVP: Replace with Algolia Geo Search for proximity search
  if params[:lieu].present?
    scope = scope.where('lieu ILIKE ?', "%#{params[:lieu]}%")
  end
  ```

---

## EPIC 6: Newsletter Subscription

### ✅ Story 6.1: Newsletter Model - Suppression Doublon Migration
- **Suppression:** migration Newsletter (déjà dans Epic 1, Story 1.1)
- **Titre story modifié:** "Newsletter Model and Validations" (focus validations uniquement)
- **Ajout note:** "Newsletter migration already exists from Epic 1, Story 1.1."

---

## EPIC 8: SEO & Discoverability

### ✅ Story 8.1: SEO Metadata Concern - meta-tags Gem
- **Ajout dans Gemfile:**
  ```ruby
  # Gemfile
  gem 'meta-tags'
  ```
- **Ajout:** instruction `bundle install`

### ✅ Story 8.3: Semantic URLs - Suppression Doublon Slug
- **Avant:** migration slug + callback
- **Après:** routing configuration uniquement (`param: :slug`)
- **Raison:** slug déjà défini dans Epic 1, Story 1.1
- **Titre story modifié:** "Semantic URLs with Slugs (Routing Configuration)"

---

## EPIC 9: Admin Interface

### ✅ Story 9.2: Admin::ScrapedUrlsController - Réutilisation detect_scraper
- **Correction:**
  ```ruby
  # ❌ AVANT: duplication logique
  scraper = case
            when url.include?('google.com/calendar') then 'GoogleCalendarScraper'
            # ...
            end

  # ✅ APRÈS: réutilisation
  scraper = ScrapingEngine.detect_scraper(@scraped_url.url)
  ```

### ✅ Stories 9.2, 9.4, 9.5: Admin Controllers - Pagy Syntax
- **Fichiers corrigés:**
  - `Admin::ScrapedUrlsController#index`
  - `Admin::ChangeLogsController#index`
  - `Admin::EventsController#index`

- **Pattern appliqué:**
  ```ruby
  # ❌ AVANT (Kaminari):
  @records = scope.page(params[:page]).per(20)

  # ✅ APRÈS (Pagy):
  @pagy, @records = pagy(scope, items: 20)
  ```

---

## Corrections Transversales

### 🔧 Pagy Syntax (5 occurrences)
Fichiers corrigés:
- `epic-04-stories.md` (Story 4.1 - EventsController)
- `epic-09-stories.md` (Story 9.2 - Admin::ScrapedUrlsController)
- `epic-09-stories.md` (Story 9.4 - Admin::ChangeLogsController)
- `epic-09-stories.md` (Story 9.5 - Admin::EventsController)

### 🔧 Slug Definition (1 centralisation)
- **Conservé dans:** Epic 1, Story 1.1 (migration + callback Event model)
- **Supprimé de:** Epic 8, Story 8.3 (routing uniquement)

### 🔧 Newsletter Migration (1 doublon supprimé)
- **Conservé dans:** Epic 1, Story 1.1
- **Supprimé de:** Epic 6, Story 6.1

---

## Résumé

**Total stories:** 48 stories across 9 epics

**Corrections par epic:**
- Epic 1: 2 corrections (photo_url, bio nullable)
- Epic 3: 4 corrections (specialized scrapers, CLI syntax, cron job, public method)
- Epic 4: 3 corrections (root route, Pagy, SEO comment)
- Epic 5: 1 correction (Algolia comment)
- Epic 6: 1 correction (migration doublon)
- Epic 8: 2 corrections (meta-tags gem, slug routing only)
- Epic 9: 4 corrections (detect_scraper reuse, Pagy syntax x3)

**Prêt pour:** Sprint Planning
