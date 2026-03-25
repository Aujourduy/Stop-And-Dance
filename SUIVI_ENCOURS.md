# SUIVI EN COURS - 3 Graces

## 🟢 En cours

Aucune tâche en cours.

---

## 🔴 À faire (Haute priorité)

### Epic 03 - Scraping URLs Management (Admin CRUD)
- Voir `_bmad-output/planning-artifacts/epic-03-stories.md`
- Stories 3.1 à 3.5

---

## 🟡 À faire (Moyenne priorité)

Aucune tâche moyenne priorité pour le moment.

---

## 🟢 À faire (Basse priorité)

Aucune tâche basse priorité pour le moment.

---

## ✅ Complété

### Session 4 (26 mars 2026)
- **Story 1.3 complétée** : Application Configuration (Environment, Jobs, Timezone)
  - dotenv-rails installé (.env.example + .env)
  - Solid Queue configuré (queues, retry strategy, inline dev mode)
  - Timezone Europe/Paris display, UTC storage
  - Solid Queue tables chargées manuellement via `rails runner`
  - ApplicationJob retry strategy: 3 attempts exponential backoff
- **Epic 02 complété à 100%** (Stories 2.1-2.5) :
  - **2.1**: Tailwind CSS v4 design system (terracotta/beige theme, custom fonts/breakpoints)
  - **2.2**: Tag/pill component réutilisable (6 variants: atelier, stage, gratuit, en_ligne, en_presentiel, default)
  - **2.3**: Homepage + hero section + CTA grid (6 boutons)
  - **2.4**: Navigation responsive (navbar desktop lg+, mobile drawer avec Stimulus)
  - **2.5**: WCAG 2.1 AA compliance (ARIA labels, focus indicators, skip link, Esc key handler)

### Session 3 (26 mars 2026)
- Story 1.1 vérifiée (7 migrations up, tous tests passent)
- **Story 1.2 complétée** : Realistic Seed Data for UI Development
  - 4 professeurs avec bios françaises réalistes
  - 20 événements futurs (mix atelier/stage, gratuit/payant, en ligne/présentiel)
  - 6 événements passés (pour tester scope Event.futurs)
  - Idempotence validée (find_or_create_by!)
  - Tous acceptance criteria validés

### Session 1 (23 mars 2026)
- Installation BMAD Method dans le projet Rails 3graces-v2
- Création du brief produit (`docs/brief.md`)
- Création complète du PRD (`docs/prd.md`)
  - Toutes les étapes complétées (1-11)
  - 41 exigences fonctionnelles (FR1-FR41)
  - 19 exigences non-fonctionnelles (NFR-P1 à NFR-SC2)
  - User journeys complets (Danny, Duy, Marc)
  - Stack technique définie (Rails 8 + PostgreSQL + Solid Queue + Claude CLI)

---

## 📝 Notes

- **Stack technique :** Rails 8 + PostgreSQL + Solid Queue + Claude Code CLI + Tailwind CSS
- **Architecture :** MPA (Multi-Page App) avec Turbo, pas de framework JS lourd
- **MVP Focus :** Scraping automatisé + affichage agenda + filtres de base + newsletter
- **Post-MVP :** Algolia recherche, géolocalisation, Cloudinary, formulaire pros
