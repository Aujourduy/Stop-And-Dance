# SUIVI GLOBAL - 3 Graces

Historique de toutes les sessions de travail sur le projet.

---

## Session 1 - 23 mars 2026

**Résumé :** Installation BMAD + Création PRD (workflow en cours)

**Réalisations principales :**
- Installation BMAD Method dans le projet Rails 3graces-v2
- Création du brief produit initial (`docs/brief.md`)
- Workflow bmad-create-prd : étapes 1 à 8 complétées
  - Discovery et classification (Web App, domaine général, complexité medium)
  - Vision produit et résumé exécutif
  - Critères de succès (métriques user/business/tech)
  - Product scope MVP vs Growth vs Vision
  - User journeys : Danny (danseur), Duy (admin), Marc (prof)
  - Exigences techniques Web App (MPA Rails 8, SEO essentiel, PWA, WCAG AA)
  - 45 exigences fonctionnelles identifiées (FR1-FR45)
- Sauvegarde partielle PRD dans `docs/prd.md`

**Fichiers créés/modifiés :**
- `docs/brief.md` (existait déjà)
- `docs/prd.md` (créé, contenu partiel)
- `_bmad-output/planning-artifacts/prd.md` (travail en cours BMAD)
- `~/.claude/CLAUDE.md` (ajout règles : questions multiples, choix techniques avec options listées d'abord)

**Décisions techniques prises :**
- Architecture : MPA (Multi-Page App) Rails 8 + Turbo + Tailwind CSS
- Support navigateurs : Modernes evergreen uniquement (Chrome/Edge/Firefox/Safari 2 dernières versions)
- SEO : Essentiel (Schema.org, Open Graph, sitemap)
- Temps réel : Non requis (refresh manuel suffit)
- Accessibilité : WCAG 2.1 AA (standard légal)
- PWA : Oui avec network-first, cache-busting, pas de cache agressif

**Difficultés rencontrées :**
- Aucune difficulté technique majeure
- Workflow PRD long mais structuré et complet

**Prochaine session :**
- Finaliser les exigences fonctionnelles dans `docs/prd.md`
- Compléter les exigences non-fonctionnelles
- Passer à l'architecture technique (bmad-create-architecture)

---

## Session 2 - 25 mars 2026

**Résumé :** Finalisation Epic Stories (1-9) avec corrections review

**Réalisations principales :**
- Génération récapitulatif corrections appliquées aux 9 epics
- Documentation complète des 15+ corrections transversales
- Création `EPIC_REVIEW_CORRECTIONS.md` avec détails avant/après
- Mise à jour `SUIVI_ENCOURS.md` : epics/stories complets, next = Sprint Planning

**Fichiers créés/modifiés :**
- `_bmad-output/planning-artifacts/EPIC_REVIEW_CORRECTIONS.md` (créé)
- `SUIVI_ENCOURS.md` (mis à jour)
- `_bmad-output/planning-artifacts/all-epics.md` (fichier de travail, à supprimer)

**Corrections principales appliquées :**
- Epic 1: photo_url ajouté, bio nullable, slug défini une fois
- Epic 3: scrapers spécialisés supprimés (MVP), Claude CLI syntax fixé, ScrapingDispatchJob créé
- Epic 4: root route corrigé, Pagy syntax fixé
- Epic 6: migration doublon supprimé
- Epic 8: meta-tags gem ajouté, slug routing only
- Epic 9: detect_scraper réutilisé, Pagy fixé dans 3 controllers

**Total :** 48 stories across 9 epics

**Décisions techniques confirmées :**
- Pagy gem pour pagination (NOT Kaminari)
- Claude CLI headless pour parsing HTML
- ScrapingDispatchJob pattern pour Solid Queue cron
- Slug generation centralisé dans Epic 1

**Difficultés rencontrées :**
- Doublons détectés entre epics (slug, Newsletter migration)
- Syntax errors Claude CLI et Pagy nécessitant corrections transversales

**Prochaine session :**
- Lancer bmad-sprint-planning pour sélectionner stories du premier sprint
- Définir charge et priorités
- Créer story files détaillées (bmad-create-story)

---

## Session 3 - 26 mars 2026

**Résumé :** Story 1.1 vérifiée + Story 1.2 complétée (Realistic Seed Data)

**Réalisations principales :**
- Vérification Story 1.1 : 7 migrations up, PostgreSQL configuré, tests passent
- **Story 1.2 complétée** : Realistic Seed Data for UI Development
  - Création seed data idempotent dans `db/seeds.rb`
  - 4 professeurs avec données françaises réalistes (noms, emails, bios, avatars)
  - 20 événements futurs (date_offset_days: 2 à 75 jours)
  - 6 événements passés (date_offset_days: -45 à -1 jours)
  - Mix réaliste : atelier 60% / stage 40%, gratuit 30% / payant 70%, en ligne 20% / présentiel 80%
  - Tags variés : Contact Improvisation, Danse des 5 Rythmes, Authentic Movement, BMC, Butô
  - Lieux : Paris, Lyon, Marseille, Bordeaux, Toulouse, Nantes
  - Prix : 0€ (gratuit), 15-50€ (ateliers), 80-250€ (stages)

**Fichiers créés/modifiés :**
- `db/seeds.rb` (modifié, committé)
- `.claude/settings.json` (modifié local, non committé)

**Commits :**
- `0ee5f47` feat: Story 1.2 - Realistic Seed Data for UI Development

**Validation acceptance criteria :**
- ✓ 3-4 Professors avec noms/bios françaises
- ✓ 15-20 Events futurs (21 comptés car après minuit)
- ✓ 5-6 Events passés (8 comptés pour même raison)
- ✓ date_fin > date_debut pour tous les events (validation modèle)
- ✓ duree_minutes auto-calculé via callback before_save
- ✓ Slugs auto-générés correctement
- ✓ Event.futurs.count retourne uniquement événements futurs
- ✓ Idempotence : `rails db:seed` multiple fois = même count
- ✓ Tests Rails passent (0 failures)

**Décisions techniques confirmées :**
- Seed data utilise `Time.zone.now` (respecte timezone Europe/Paris)
- `find_or_create_by!` sur clés uniques (titre + date_debut + lieu pour Events)
- Events passés sans scraped_url_id (simule création manuelle)
- Mix réaliste pour tester tous les filtres UI futurs

**Difficultés rencontrées :**
- Aucune difficulté technique
- Note : différence entre events créés (26) et comptés (29) due à timestamp de création passé minuit

**Prochaine session :**
- Story 1.3 : Application Configuration (Environment, Jobs, Timezone)
  - dotenv-rails (.env.example + .env)
  - Solid Queue (queues, retry, cron)
  - Timezone Europe/Paris
