# Stop & Dance — Règles Projet

## SURCHARGES DU CLAUDE.MD GLOBAL

### Override Règle 2 — PENDANT L'EXÉCUTION DES STORIES
Quand Duy a lancé l'exécution des stories ("go", "continue", "enchaîne"), ne PAS s'arrêter entre les stories pour proposer des options.
Enchaîner : story suivante → tests → commit → push → story suivante.
La règle 2 reste active pour toute AUTRE discussion.

### Override Règle 3 (Démarrage session)
Ce projet N'UTILISE PAS SUIVI_ENCOURS.md ni SUIVI_ARCHITECTURE.md.
Au démarrage : lire ce fichier + `git log --oneline` (dernier commit feat: Story X.X = dernière story terminée).
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
Enchaîner : story → tests → commit → push → story suivante → jusqu'à fin de tous les epics.
Un résumé n'est PAS un problème bloquant.
STOP uniquement si erreur technique bloquante nécessitant intervention humaine.

---

## Projet

Agenda danse exploratoire France. Site read-only, zéro compte utilisateur.
Rails 8, PostgreSQL, Solid Queue, Tailwind CSS v4, Turbo, Pagy.

### ⚠️ IMPORTANT : Tailwind CSS v4 Configuration

**Ce projet utilise Tailwind CSS v4** qui fonctionne DIFFÉREMMENT de v3 !

❌ `tailwind.config.js` pour ajouter couleurs custom NE FONCTIONNE PLUS (méthode v3)
✅ Ajouter couleurs dans `app/assets/tailwind/application.css` avec directive `@theme`

**Process :** Éditer `app/assets/tailwind/application.css` → ajouter `--color-xxx` dans `@theme` → `bin/rails tailwindcss:build` → relancer serveur → utiliser `bg-xxx` dans vues

**Couleurs disponibles :** terracotta, beige, dark-bg, moutarde (custom) + green/blue/red/gray-XXX (variants utilisés)

---

## Définition de "Story terminée"

Une story est terminée UNIQUEMENT quand :
1. Code écrit selon acceptance criteria
2. Tests écrits ET passent (`rails test`)
3. Tests système passent (`rails test:system`)
4. Routes impactées testées avec curl (status 200)
5. Si modif code existant → tests impactés (unitaires + système) mis à jour
6. Tests qui échouent après modif → CORRIGER avant commit, JAMAIS supprimer
7. Commit + push

Si tests ou curl échouent → corriger avant de passer à la suite.

---

## Audit QA — Après le dernier Epic de chaque session

Jouer le rôle de QA Engineer. Audit complet via slash command `/qa` ou manuel.

**8 sections :** Tests unitaires, tests système, routes (curl), liens (link_to), modèles (associations), vues (partials), conventions CLAUDE.md, tests UX.

**Spécificités projet :**

**Routes à tester (curl sur port 3002) :**
- Publiques : /, /evenements, /evenements/:slug, /professeurs/:id, /professeurs/:id/stats, /professeurs/:id/redirect_to_site, /a-propos, /contact, /proposants, /sitemap.xml
- Admin (HTTP Basic Auth) : /admin, /admin/scraped_urls (index, new, show, edit, preview), /admin/events (index, show, edit), /admin/change_logs (index, show)

**Conventions spécifiques à vérifier :**
- Pagy utilisé partout (JAMAIS `.page().per()` Kaminari)
- `Time.current` dans scopes (JAMAIS `Date.current`)
- `increment_counter` pour compteurs (JAMAIS `increment!`)
- Timezone : `config.active_record.default_timezone = :utc`
- Routes publiques en français (/evenements, /professeurs)

**Tests système UX :**
Capybara + Playwright local (PAS Selenium), port 3002.
Scénarios : Homepage (Hero, navbar), liste événements, filtres (Gratuit, date), modal, newsletter, infinite scroll, admin (HTTP Basic).

**Process :** Pour chaque bug → corriger, tester, commit + push → rapport final `tmp/QA_AUDIT_[DATE].md`

**Détails complets :** `~/.claude/commands/qa.md`

---

## Conventions à respecter PARTOUT

- **Timezone** : UTC en base, Europe/Paris affichage. JAMAIS stocker en local.
- **Pagination** : Pagy (`@pagy, @records = pagy(scope)`). JAMAIS `.page().per()`.
- **Compteurs** : `Professor.increment_counter(:x, id)`. JAMAIS `increment!`.
- **Scopes temps** : `Time.current` dans Event.futurs. JAMAIS `Date.current`.
- **Jobs** : retry exponentiel 3x. ScrapingDispatchJob enqueue les ScrapingJobs.
- **Routes publiques** : français (/evenements, /professeurs).
- **Scraping MVP** : un seul HtmlScraper générique, pas de scrapers spécialisés.

---

## Vérification du Scraping

**Protocole complet :** `docs/verification-scraping.md`

Après chaque scraping (nouveau ScrapedUrl, modif code scraping, parsing Claude nouvelle source), vérifier :
- Comptage événements extraits (≥ 1)
- Timestamps (HTML, Markdown, Claude) renseignés
- Cohérence données (dates, prix/gratuit, professor_id)
- Correspondance site source vs DB (≥ 80%)
- Affichage site public + admin preview OK

**Commandes rapides et checklist complète dans la doc.**

---

## Ordre des Epics

Epic 1 DÉBUT → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → Epic 1 FIN (Docker/prod en dernier).

---

## Mise à jour état projet — AVANT chaque commit significatif

**IMPORTANT** : MAJ `docs/etat-projet.md` + sync Gist AVANT commit significatif (features/corrections/stories, PAS typos).

**Pourquoi ?** Session interrompue = état cohérent dans Gist → claude.ai voit état réel → trace précise dans git.

**Process :**
1. MAJ `docs/etat-projet.md` : date, epics/stories terminés, epic en cours, fonctionnalités, problèmes, prochaines étapes
2. Lancer `bin/sync-gist.sh` (sync vers Gist GitHub secret, credentials ~/.env-stopanddance)
3. Commit avec docs/etat-projet.md inclus

**Commits significatifs :** Story terminée, Epic terminé, bug majeur, refactor important (PAS typos).

---

## Contexte serveur

**Infrastructure locale :**
- PostgreSQL local (user dang, peer auth)
- Docker v1 en parallèle — NE PAS TOUCHER
- Ports occupés : 3000, 3001, 80, 443
- Dev Rails v2 : port 3002
- Tests système : Capybara + Playwright local (Chromium)

**IMPORTANT - Serveur Rails :**
`bin/rails server -b 0.0.0.0 -p 3002`
Bind 0.0.0.0 OBLIGATOIRE (serveur headless, accès réseau local via Tailscale VPN).
JAMAIS localhost uniquement (inaccessible depuis navigateur).

**Réseau/déploiement :**
- Tailscale : VPN mesh privé (IP 100.x.x.x)
- Cloudflare : DNS + proxy HTTPS (stopand.dance)
- HTTPS : géré par Cloudflare uniquement (PAS Caddy/Let's Encrypt)
- Admin : restreint VPN Tailscale (optionnel)

**Aide :** WebSearch ou WebFetch si bloqué.
