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
