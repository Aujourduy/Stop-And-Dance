# Stop & Dance — Règles Projet

## SURCHARGES DU CLAUDE.MD GLOBAL

### Override Règle 2 — PENDANT L'EXÉCUTION DES STORIES
Quand Duy a lancé l'exécution des stories ("go", "continue", "enchaîne"),
ne PAS s'arrêter entre les stories pour proposer des options.
Enchaîner story suivante → tests → commit → push → story suivante.
La règle 2 reste active pour toute AUTRE discussion.

### Override Règle 3 (Démarrage session)
Ce projet N'UTILISE PAS SUIVI_ENCOURS.md ni SUIVI_ARCHITECTURE.md.
Au démarrage, lire ce fichier puis le fichier story de l'epic en cours.
Pour savoir où on en est : `git log --oneline` — le dernier commit
feat: Story X.X indique la dernière story terminée.
Stories : `_bmad-output/planning-artifacts/epic-*.md`
Architecture : `_bmad-output/planning-artifacts/architecture.md`
Maquette UI : `docs/ui-reference.md` et `docs/ui-reference.jsx`

### Override Règle 4 et 8 (Git) — MODE AUTONOME
Commits et push AUTORISÉS SANS mot-clé ni token.
Commit + push automatique après chaque story réussie.
Format : `feat: Story X.X - Description`
La protection git-firewall.sh est désactivée pour ce projet.

### Mode continu
Ne PAS s'arrêter entre les epics pour faire un bilan ou résumé.
Enchaîner : story → tests → commit → push → story suivante →
jusqu'à ce que toutes les stories de tous les epics soient terminées.
Un résumé n'est PAS un problème bloquant.
STOP uniquement si erreur technique bloquante nécessitant intervention humaine.

---

## Projet
Agenda danse exploratoire France. Site read-only, zéro compte utilisateur.
Rails 8, PostgreSQL, Solid Queue, Tailwind CSS v4, Turbo, Pagy.

### ⚠️ IMPORTANT : Tailwind CSS v4 Configuration

**Ce projet utilise Tailwind CSS v4** qui fonctionne DIFFÉREMMENT de v3 !

**❌ NE FONCTIONNE PLUS :**
- `tailwind.config.js` pour ajouter des couleurs custom (méthode v3)

**✅ NOUVELLE MÉTHODE v4 :**
- Ajouter les couleurs dans `app/assets/tailwind/application.css` avec la directive `@theme`

**Exemple :**
```css
@theme {
  --color-ma-couleur: #FF5733;
  --color-ma-couleur-dark: #CC4629;
}
```

**Process complet :**
1. Éditer `app/assets/tailwind/application.css` → ajouter `--color-xxx` dans `@theme`
2. Recompiler : `bin/rails tailwindcss:build`
3. Relancer le serveur Rails
4. Utiliser dans les vues : `bg-ma-couleur`, `text-ma-couleur`, etc.

**Couleurs déjà disponibles :**
- Custom : `terracotta`, `beige`, `dark-bg`, `moutarde`
- Tailwind base : `green-XXX`, `blue-XXX`, `red-XXX`, `gray-XXX` (limitées aux variants utilisés)

---

## Définition de "Story terminée"
Une story est terminée UNIQUEMENT quand :
1. Code écrit selon acceptance criteria
2. Tests écrits ET passent (`rails test`)
3. Tests système passent (`rails test:system`)
4. Routes impactées testées avec curl (status 200)
5. Si la story modifie du code existant, les tests impactés 
   (unitaires + système) sont mis à jour pour refléter les changements
6. Les tests existants qui échouent après une modif DOIVENT être 
   corrigés avant commit, JAMAIS supprimés
7. Commit + push
Si tests ou curl échouent, corriger avant de passer à la suite.
---

## Audit QA — Après le dernier Epic de chaque session

Jouer le rôle de QA Engineer. Audit complet de l'application :

### 1. TESTS
Lancer `rails test` — TOUT doit passer. Zéro failure, zéro error.

### 2. ROUTES
Lancer le serveur sur port 3002, curl TOUTES les routes, vérifier status 200 :

**Routes publiques :**
- GET /
- GET /evenements
- GET /evenements/:slug (premier event des seeds)
- GET /professeurs/:id (premier prof des seeds)
- GET /professeurs/:id/stats
- GET /professeurs/:id/redirect_to_site (vérifie redirect 303)
- GET /a-propos
- GET /contact
- GET /proposants
- GET /sitemap.xml

**Routes admin (avec auth HTTP Basic) :**
- GET /admin
- GET /admin/scraped_urls
- GET /admin/scraped_urls/new
- GET /admin/scraped_urls/:id
- GET /admin/scraped_urls/:id/edit
- GET /admin/scraped_urls/:id/preview
- GET /admin/events
- GET /admin/events/:id
- GET /admin/events/:id/edit
- GET /admin/change_logs
- GET /admin/change_logs/:id

### 3. LIENS
Vérifier que tous les `link_to` dans les vues pointent vers des routes
qui existent. Grep les helpers de route utilisés dans `app/views/` et
croiser avec `rails routes`.

### 4. MODÈLES
Vérifier que les associations (belongs_to, has_many, has_many :through)
sont cohérentes :
- Pas de données orphelines dans les seeds
- Event.professor n'est JAMAIS nil pour les events affichés
- Chaque belongs_to optionnel est protégé dans les vues (&. ou if)

### 5. VUES
Vérifier que chaque partial appelé avec `render` :
- Existe au bon chemin
- Reçoit les bonnes variables locales
- Ne plante pas sur des données nil (professor, scraped_url, etc.)

### 6. CONVENTIONS CLAUDE.MD
Grep et vérifier dans tout le code :
- Pagy utilisé partout, PAS Kaminari (JAMAIS `.page().per()`)
- `Time.current` dans les scopes, PAS `Date.current`
- `increment_counter` pour compteurs, PAS `increment!`
- Timezone : `config.active_record.default_timezone = :utc`
- Routes publiques en français (/evenements, /professeurs)

### 7. RAPPORT
Pour chaque bug trouvé : corriger, tester, commit, push.
Faire un rapport final listant tout ce qui a été corrigé.

### 8. TESTS SYSTÈME (UX)
Utiliser Capybara + Playwright local (PAS Selenium, PAS container Docker Playwright v1).
Driver: `capybara-playwright-driver`, browser: Chromium headless, port 3002.
Config: `test/application_system_test_case.rb`

Écrire des tests système pour les interactions utilisateur :
- Homepage : charge OK, affiche Hero, navbar
- Liste événements : affiche des events
- Filtres : cocher "Gratuit" → seuls events gratuits affichés
- Filtres : entrer date → filtrage OK
- Modal : cliquer event → modal s'ouvre
- Newsletter : remplir email → flash message succès
- Infinite scroll : scroll → batch suivant chargé
- Admin : login HTTP Basic → accès admin OK

Lancer avec `rails test:system` — tout doit passer.

---

## Conventions à respecter PARTOUT

- **Timezone** : UTC en base, Europe/Paris à l'affichage. JAMAIS stocker en local.
- **Pagination** : Pagy (`@pagy, @records = pagy(scope)`). JAMAIS `.page().per()`.
- **Compteurs** : `Professor.increment_counter(:x, id)`. JAMAIS `increment!`.
- **Scopes temps** : `Time.current` dans Event.futurs. JAMAIS `Date.current`.
- **Jobs** : retry exponentiel 3x. ScrapingDispatchJob enqueue les ScrapingJobs.
- **Routes publiques** : français (/evenements, /professeurs).
- **Scraping MVP** : un seul HtmlScraper générique, pas de scrapers spécialisés.

---

## Ordre des Epics
Epic 1 DÉBUT → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → Epic 1 FIN (Docker/prod en dernier).

---

## Mise à jour état projet — AVANT chaque commit significatif

**IMPORTANT** : Mettre à jour `docs/etat-projet.md` + sync Gist **AVANT chaque commit significatif** (pas typos, mais features/corrections/stories).

**Pourquoi ?**
- Si session interrompue, état cohérent dans Gist
- claude.ai voit toujours l'état réel du projet
- Trace historique précise dans git

**Process AVANT chaque commit significatif :**

1. **Mettre à jour** `docs/etat-projet.md` :
   - Date de dernière mise à jour
   - Epics/stories terminés
   - Epic en cours + prochaine story
   - Fonctionnalités implémentées
   - Problèmes résolus/connus
   - Prochaines étapes

2. **Lancer** `bin/sync-gist.sh`
   - Synchronise vers Gist GitHub (secret)
   - claude.ai peut lire l'état (repo privé inaccessible)
   - Credentials : ~/.env-stopanddance (GIST_ID, GIST_TOKEN)

3. **Commit** avec docs/etat-projet.md inclus

**Exemples de commits significatifs :**
- ✅ Story terminée (feat: Story X.X)
- ✅ Epic terminé (feat: Epic X)
- ✅ Correction bug majeur (fix: problème bloquant)
- ✅ Refactor important (refactor: architecture)
- ❌ Fix typo (docs: correction typo) → pas besoin de maj état

---

## Contexte serveur

### Infrastructure locale
- PostgreSQL local (user dang, peer auth, pas de mot de passe)
- Docker v1 tourne en parallèle — NE PAS TOUCHER
- Ports occupés : 3000, 3001, 80, 443
- Dev Rails v2 sur port 3002
- Tests système : Capybara + Playwright local (Chromium)

**IMPORTANT - Serveur Rails :**
- Toujours lancer avec : `bin/rails server -b 0.0.0.0 -p 3002`
- Le bind sur 0.0.0.0 est OBLIGATOIRE (serveur headless, accès réseau local)
- JAMAIS localhost uniquement (sinon inaccessible depuis navigateur)
- Raison : serveur distant accessible via Tailscale VPN

### Réseau et déploiement
- **Tailscale** : VPN mesh privé, serveur accessible via IP 100.x.x.x
- **Cloudflare** : DNS + proxy HTTPS pour stopand.dance
- **HTTPS** : Géré par Cloudflare uniquement, PAS par Caddy/Let's Encrypt
- **Admin** : Peut être restreint au réseau Tailscale (accès VPN uniquement)

### Aide
Si bloqué : WebSearch ou WebFetch pour consulter la documentation.