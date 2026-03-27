# Documentation Stop & Dance

Guides et documentation technique du projet Stop & Dance.

---

## 📚 Guides utilisateur

### [Guide Scraping](guide-scraping.md)
Guide complet pour ajouter des sources, lancer le scraping et vérifier les résultats.

**Contenu** :
- Ajouter une URL à scraper (console + seeds)
- Lancer le scraping (test dry-run + scraping réel)
- Vérifier les résultats (events, professeurs, changeLogs)
- Debugging et troubleshooting
- Notes correctrices pour améliorer le parsing
- Cheatsheet commandes rapides

**Pour qui** : Administrateur technique (ligne de commande)

---

### [Guide Administrateur](guide-admin.md)
Interface web d'administration pour gérer les sources et événements.

**Contenu** :
- Connexion à l'interface admin (`/admin`)
- HTTP Basic Auth (credentials)
- Gestion des ScrapedUrls (CRUD, scraper maintenant)
- Consultation ChangeLogs (diff HTML)
- Gestion manuelle des Events
- Sécurité et bonnes pratiques

**Pour qui** : Administrateur (interface graphique)

**Accès** : `http://localhost:3002/admin` (dev) ou `https://stopand.dance/admin` (prod)

---

## 🏗️ Documentation technique

### [Architecture Scraping](scraping-architecture.md)
Architecture technique du système de scraping automatisé.

**Contenu** :
- Modèle de données (ScrapedUrl, Professor, Event, ChangeLog)
- Déduplication des professeurs (nom normalisé)
- Règles de scraping (détection changements HTML)
- Multi-sourcing et types de sources
- Gestion erreurs et retry
- Fichiers et structure code

**Pour qui** : Développeur

---

### [Product Requirements Document (PRD)](prd.md)
Spécifications fonctionnelles complètes du projet.

**Contenu** :
- 41 exigences fonctionnelles (FR1-FR41)
- 19 exigences non-fonctionnelles (NFR)
- Cas d'usage détaillés
- Contraintes techniques

**Pour qui** : Product Manager, Développeur

---

### [Product Brief](brief.md)
Vision produit et contexte du projet.

**Contenu** :
- Problème résolu
- Public cible
- Proposition de valeur
- Success metrics

**Pour qui** : Product Manager, Stakeholders

---

### [UI Reference](ui-reference.md)
Design system et composants UI.

**Contenu** :
- Palette couleurs (terracotta/beige)
- Composants réutilisables
- Patterns de navigation
- Accessibilité WCAG 2.1 AA

**Pour qui** : Designer, Développeur frontend

**Composant React** : `ui-reference.jsx` (maquette interactive)

---

### [État du Projet](etat-projet.md)
État actuel du projet, sessions de développement et prochaines étapes.

**Contenu** :
- Epics terminés (1-9)
- Fonctionnalités implémentées
- Architecture technique
- Outils développement
- Notes sessions récentes
- Prochaines actions suggérées

**Pour qui** : Toute l'équipe, claude.ai (sync Gist)

---

## 🚀 Quick Start

### Développement local

```bash
# Lancer serveur dev
bin/rails s -b 0.0.0.0 -p 3002

# Accès site public
http://localhost:3002

# Accès admin
http://localhost:3002/admin
# Username: admin
# Password: change_me_in_production
```

### Premier scraping

**Via interface admin** :
1. Aller sur `http://localhost:3002/admin`
2. Cliquer "Nouvelle URL"
3. Remplir formulaire (URL, nom, notes)
4. Créer → Cliquer "🔄 Scraper maintenant"
5. Attendre 30-60s → Recharger
6. Vérifier `/admin/events` pour voir les events créés

**Via console Rails** :
```bash
bin/rails console
> ScrapedUrl.create!(url: "...", nom: "...", statut_scraping: "actif")
> exit
bin/rails scraping:test[1]  # Dry-run
bin/rails scraping:run[1]   # Scraping réel
```

---

## 📖 Pour aller plus loin

### Tests

```bash
# Tous les tests
bin/rails test

# Tests modèle Professor (déduplication)
bin/rails test test/models/professor_test.rb

# Tests système (Capybara + Playwright)
bin/rails test:system
```

### Maintenance

```bash
# Backfill nom_normalise (une fois après migration)
bin/rails professors:backfill_nom_normalise

# Scraper toutes les URLs actives
bin/rails scraping:run_all

# Synchroniser état projet avec Gist
bin/sync-gist.sh
```

### Production

```bash
# Démarrer containers Docker
ddup  # Alias : docker compose up -d

# Logs
docker compose logs -f web

# Backup DB
bin/backup-db.sh
```

---

## 📞 Support

- **Issues GitHub** : https://github.com/Aujourduy/Stop-And-Dance/issues
- **Documentation Claude Code** : https://docs.claude.com/en/docs/claude-code
- **Logs** : `log/development.log` ou `log/production.log`

---

**Dernière mise à jour** : 2026-03-27
