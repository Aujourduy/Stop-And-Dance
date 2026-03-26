# 3 Graces — Règles Projet

## SURCHARGES DU CLAUDE.MD GLOBAL

### Override Règle 3 (Démarrage session)
Ce projet N'UTILISE PAS SUIVI_ENCOURS.md ni SUIVI_ARCHITECTURE.md.
Au démarrage, lire ce fichier puis le fichier story de l'epic en cours.
Stories : `_bmad-output/planning-artifacts/epic-*.md`
Architecture : `_bmad-output/planning-artifacts/architecture.md`
Maquette UI : `docs/ui-reference.md` et `docs/ui-reference.jsx`

### Override Règle 4 et 8 (Git) — MODE AUTONOME
Commits et push AUTORISÉS SANS mot-clé ni token.
Commit + push automatique après chaque story réussie.
Format : `feat: Story X.X - Description`
La protection git-firewall.sh est désactivée pour ce projet.

---

## Projet
Agenda danse exploratoire France. Site read-only, zéro compte utilisateur.
Rails 8, PostgreSQL, Solid Queue, Tailwind, Turbo, Pagy.

## Conventions à respecter PARTOUT

- **Timezone** : UTC en base, Europe/Paris à l'affichage. JAMAIS stocker en local.
- **Pagination** : Pagy (`@pagy, @records = pagy(scope)`). JAMAIS `.page().per()`.
- **Compteurs** : `Professor.increment_counter(:x, id)`. JAMAIS `increment!`.
- **Scopes temps** : `Time.current` dans Event.futurs. JAMAIS `Date.current`.
- **Jobs** : retry exponentiel 3x. ScrapingDispatchJob enqueue les ScrapingJobs.
- **Routes publiques** : français (/evenements, /professeurs).
- **Scraping MVP** : un seul HtmlScraper générique, pas de scrapers spécialisés.

## Ordre des Epics
Epic 1 DÉBUT → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → Epic 1 FIN (Docker/prod en dernier).

## Contexte serveur
- PostgreSQL local (user dang, peer auth, pas de mot de passe)
- Docker v1 tourne en parallèle — NE PAS TOUCHER
- Ports occupés : 3000, 3001, 80, 443
- Si bloqué : WebSearch ou WebFetch pour la doc

### Override Règle 2 — PENDANT L'EXÉCUTION DES STORIES
Quand Duy a lancé l'exécution des stories ("go", "continue", "enchaîne", ...), 
ne PAS s'arrêter entre les stories pour proposer des options.
Enchaîner story suivante → tests → commit → push → story suivante.
La règle 2 reste active pour toute AUTRE discussion.


### Définition de "Story terminée"
Une story est terminée UNIQUEMENT quand :
1. Code écrit selon acceptance criteria
2. Tests écrits ET passent (`rails test`)
3. Commit + push
Si les tests échouent, corriger avant de passer à la suite.
