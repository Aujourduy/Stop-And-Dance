# SUIVI EN COURS - 3 Graces

## 🟢 En cours

Aucune tâche en cours.

---

## 🔴 À faire (Haute priorité)

### Story 1.3 - Application Configuration (Environment, Jobs, Timezone)
- Configurer dotenv-rails (.env.example + .env)
- Configurer Solid Queue (queues, retry strategy, cron placeholder)
- Configurer timezone (Europe/Paris display, UTC storage)
- **Fichier :** `_bmad-output/planning-artifacts/epic-01-stories.md` (lignes 141-204)

---

## 🟡 À faire (Moyenne priorité)

Aucune tâche moyenne priorité pour le moment.

---

## 🟢 À faire (Basse priorité)

Aucune tâche basse priorité pour le moment.

---

## ✅ Complété

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
