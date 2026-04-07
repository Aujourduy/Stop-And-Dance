# Guide Administrateur — Stop & Dance

Interface d'administration pour gérer les sources de scraping, les événements et consulter les logs.

---

## Table des matières

1. [Accès à l'interface admin](#1-accès-à-linterface-admin)
2. [Dashboard principal](#2-dashboard-principal)
3. [Gestion des ScrapedUrls](#3-gestion-des-scrapedurls)
4. [Consultation des ChangeLogs](#4-consultation-des-changelogs)
5. [Gestion des Events](#5-gestion-des-events)
6. [Actions rapides](#6-actions-rapides)
7. [Crawler de sites](#7-crawler-de-sites)
8. [Sécurité](#8-sécurité)

---

## 1. Accès à l'interface admin

### URL

**Développement** :
```
http://localhost:3002/admin
```

**Production** :
```
https://stopand.dance/admin
```

### Authentification HTTP Basic

L'accès admin est protégé par **HTTP Basic Authentication**.

**Credentials par défaut** :
- Username : `admin`
- Password : `change_me_in_production`

⚠️ **IMPORTANT** : Changer le mot de passe en production !

### Configuration des credentials

**Fichier** : `~/.env-stopanddance` (ou variables d'environnement serveur)

```bash
# Éditer le fichier
nano ~/.env-stopanddance
```

```bash
# Ajouter/modifier
ADMIN_USERNAME=votre_username
ADMIN_PASSWORD=votre_password_securise
```

**Recharger l'application** :
```bash
# Development
# Redémarrer le serveur Rails (Ctrl+C puis bin/rails s -b 0.0.0.0 -p 3002)

# Production
bin/rails restart  # Ou docker restart stopanddance_web
```

### Test accès admin

```bash
# Curl avec auth
curl -u admin:change_me_in_production http://localhost:3002/admin

# Ou via navigateur
# → Ouvrir http://localhost:3002/admin
# → Popup login HTTP Basic apparaît
# → Entrer username + password
```

---

## 2. Dashboard principal

**URL** : `/admin`

**Contenu** :
- Liste des **ScrapedUrls** (sources de scraping)
- Pagination (20 par page)
- Tri par date de création (plus récent en premier)

**Actions disponibles** :
- ➕ **Nouvelle URL** : Ajouter une source
- 👁️ **Voir** : Détails d'une source
- ✏️ **Éditer** : Modifier une source
- 🗑️ **Supprimer** : Supprimer une source
- 🔄 **Scraper maintenant** : Lancer scraping immédiat
- 👁️‍🗨️ **Prévisualiser HTML** : Voir le HTML actuel de la source

---

## 3. Gestion des ScrapedUrls

### A. Ajouter une nouvelle URL

1. Cliquer sur **"Nouvelle URL"** dans le dashboard
2. Remplir le formulaire :
   - **URL** (requis) : URL complète à scraper
   - **Nom** (optionnel) : Label descriptif (ex: "Site de Marie Dupont")
   - **Notes correctrices** (optionnel) : Instructions pour Claude CLI
   - **Statut scraping** : `actif` ou `inactif`
3. Cliquer **"Créer"**

**Exemple** :
```
URL: https://danse-contact-paris.fr/agenda
Nom: Agenda Danse Contact Paris
Notes correctrices: Les événements sont dans <div class='event-card'>.
                    Le prix est dans <span class='price'>.
Statut: actif
```

### B. Éditer une URL existante

1. Cliquer sur **"Éditer"** à côté de l'URL
2. Modifier les champs
3. Cliquer **"Mettre à jour"**

**Cas d'usage fréquents** :
- Corriger une URL cassée
- Affiner les **notes correctrices** si le parsing est imprécis
- Désactiver temporairement (`statut: inactif`) sans supprimer

### C. Voir les détails d'une URL

**URL** : `/admin/scraped_urls/:id`

**Contenu affiché** :
- URL, nom, notes correctrices, statut
- **Erreurs consécutives** : Nombre d'échecs de scraping
- **Dernière mise à jour** : Timestamp
- **Professeurs associés** : Liste des profs scrapés depuis cette source
- **10 derniers ChangeLogs** : Historique des changements HTML détectés

**Actions** :
- 🔄 **Scraper maintenant** : Déclenche scraping immédiat
- 👁️‍🗨️ **Prévisualiser HTML** : Voir le HTML actuel

### D. Prévisualiser le HTML

**URL** : `/admin/scraped_urls/:id/preview`

**Utilité** :
- Voir le HTML brut actuellement stocké (`derniere_version_html`)
- Vérifier si le HTML a la structure attendue
- Déboguer pourquoi le parsing échoue

**Affichage** :
- HTML brut dans `<pre><code>` (syntax highlighting possible)
- Taille du HTML en bytes
- Timestamp de dernière maj

### E. Scraper maintenant (action manuelle)

**Bouton** : "🔄 Scraper maintenant"

**Ce qui se passe** :
1. Enqueue un `ScrapingJob` pour cette URL
2. Le job s'exécute en arrière-plan (Solid Queue)
3. Redirection vers la page de détail avec message de confirmation
4. Recharger la page après quelques secondes pour voir les résultats

**Vérifier l'exécution** :
```bash
# Console Rails
bin/rails console
> SolidQueue::Job.where(queue_name: "scraping").last
```

### F. Supprimer une URL

**Bouton** : "🗑️ Supprimer"

⚠️ **ATTENTION** : Suppression en cascade !
- ❌ Supprime tous les **ChangeLogs** associés
- ❌ Met `scraped_url_id` à NULL dans les **Events** (events deviennent "manuels")
- ⚠️ **Les Events ne sont PAS supprimés** (seulement déliés de la source)

**Confirmation** : Demande confirmation avant suppression

---

## 4. Consultation des ChangeLogs

**URL** : `/admin/change_logs`

**Contenu** :
- Liste des **changements HTML détectés** par le scraping
- Pagination (20 par page)
- Tri par date (plus récent en premier)

**Informations affichées** :
- **Date/heure** du changement
- **ScrapedUrl** concernée
- **Lignes ajoutées** : Nombre de lignes HTML ajoutées
- **Lignes supprimées** : Nombre de lignes HTML supprimées
- **Action** : Voir le diff HTML complet

### Voir le diff HTML

**URL** : `/admin/change_logs/:id`

**Contenu** :
- **Diff HTML** complet (format diff ligne par ligne)
- **Changements détectés** (JSON) :
  - `lines_added`
  - `lines_removed`
  - `timestamp`
- **ScrapedUrl** source

**Utilité** :
- Auditer ce qui a changé sur un site externe
- Comprendre pourquoi de nouveaux events ont été créés
- Déboguer des changements inattendus

---

## 5. Gestion des Events

**URL** : `/admin/events`

**Contenu** :
- Liste des **événements** créés (manuels + scrapés)
- Pagination (20 par page)
- Tri par date de début (plus récent en premier)

**Informations affichées** :
- Titre
- Date début/fin
- Professeur
- Source (ScrapedUrl ou "Manuel")
- Prix
- Type (atelier/stage)
- Statut (gratuit, en ligne, en présentiel)

**Actions** :
- 👁️ **Voir** : Détails complets
- ✏️ **Éditer** : Corriger manuellement un event

### Éditer un événement

**URL** : `/admin/events/:id/edit`

**Cas d'usage** :
- Corriger une erreur de parsing (titre, date, prix)
- Compléter des informations manquantes
- Associer à un autre professeur
- Changer le type (atelier → stage)

**Champs éditables** :
- Titre, description
- Date début/fin
- Lieu, adresse complète
- Prix normal, prix réduit
- Type event (atelier/stage)
- Gratuit, en ligne, en présentiel
- Tags
- Professeur (dropdown)

---

## 6. Actions rapides

### Lister les URLs avec erreurs

Depuis le dashboard `/admin`, chercher les URLs avec badge rouge "⚠️ X erreurs".

**Ou via console** :
```ruby
ScrapedUrl.where("erreurs_consecutives > 0")
```

### Réinitialiser compteur erreurs

1. Aller sur `/admin/scraped_urls/:id`
2. Cliquer "Éditer"
3. **Problème** : Le champ `erreurs_consecutives` n'est pas éditable dans le formulaire

**Solution via console** :
```bash
bin/rails console
```

```ruby
scraped_url = ScrapedUrl.find(1)
scraped_url.update!(erreurs_consecutives: 0)
```

### Forcer re-scraping complet

Si le HTML est détecté comme inchangé mais tu veux forcer un nouveau scraping :

```ruby
# Console Rails
scraped_url = ScrapedUrl.find(1)
scraped_url.update!(derniere_version_html: nil)
# Puis cliquer "Scraper maintenant" dans l'admin
```

### Voir les jobs Solid Queue en cours

```bash
bin/rails console
```

```ruby
# Jobs en attente
SolidQueue::Job.where(queue_name: "scraping").count

# Jobs en échec
SolidQueue::FailedExecution.last(5)
```

---

## 7. Crawler de sites

### Principe

Le crawler explore le site d'un professeur à partir d'une URL racine, et détecte automatiquement les pages contenant des ateliers/stages grâce à un LLM gratuit (OpenRouter). Les pages détectées sont automatiquement ajoutées comme nouvelles sources de scraping.

### Lancer un crawl

1. Aller sur `/admin/scraped_urls/:id` (page détails d'une URL)
2. Section **"Crawler le site"** (violet)
3. Choisir le modèle LLM (optionnel, défaut = celui des paramètres)
4. Cliquer **"Crawler le site"**
5. Le crawl s'exécute en arrière-plan

### Consulter les résultats

**URL** : `/admin/site_crawls`

- Liste des crawls avec statut (pending/running/completed/failed)
- Nombre de pages trouvées
- Oui / Non (pages classées par le LLM)
- Modèle LLM utilisé

**Détail d'un crawl** : `/admin/site_crawls/:id`

- Table de toutes les pages crawlées
- Verdict : ✅ (atelier détecté), ❌ (pas d'atelier), ⚠️ (erreur)
- Profondeur, URL, statut HTTP

### Auto-recrawl

Pour activer le re-crawl automatique quotidien :
1. Éditer la ScrapedUrl (`/admin/scraped_urls/:id/edit`)
2. Cocher **"Auto-recrawl"**
3. Le `SiteCrawlDispatchJob` (4h du matin) vérifiera si la page racine a changé
4. Si oui → re-crawl complet automatique

### Configurer le modèle LLM

**URL** : `/admin/settings/edit`

Champ **"Modèle OpenRouter par défaut"** : choisir parmi les modèles gratuits disponibles.

Modèles testés :
- `google/gemma-3n-e4b-it:free` — rapide, bon pour classification
- `google/gemma-3-12b-it:free` — plus précis, parfois rate-limité
- `google/gemma-3-27b-it:free` — meilleur, souvent rate-limité

### Limites

- **Max 100 pages** par crawl
- **Profondeur max 5** niveaux de liens
- **Même domaine** uniquement (pas de liens externes)
- **Rate limit** : les modèles gratuits OpenRouter limitent ~20 req/min
- **Pages JS-only** : fallback automatique Playwright (plus lent)

---

## 8. Sécurité

### A. Changer les credentials admin

⚠️ **OBLIGATOIRE EN PRODUCTION**

```bash
# Éditer ~/.env-stopanddance
nano ~/.env-stopanddance
```

```bash
# Utiliser un mot de passe fort (20+ caractères)
ADMIN_USERNAME=admin_stopanddance
ADMIN_PASSWORD=Tr0ubl3_D@ns3_S3cur3_2026!
```

**Générer un mot de passe fort** :
```bash
openssl rand -base64 32
```

### B. Restreindre accès par IP (optionnel)

**Tailscale uniquement** : Limiter accès admin au VPN

**Nginx/Caddy** :
```nginx
location /admin {
  allow 100.x.x.x;  # IP Tailscale
  deny all;
  proxy_pass http://localhost:3002;
}
```

**Ou via Rails** : Ajouter dans `Admin::ApplicationController`

```ruby
before_action :restrict_to_tailscale

def restrict_to_tailscale
  allowed_ips = ["100.95.124.70"]  # Ton IP Tailscale
  unless allowed_ips.include?(request.remote_ip)
    render plain: "Access denied", status: :forbidden
  end
end
```

### C. Logs d'accès admin

**Activer logging** :

```ruby
# app/controllers/admin/application_controller.rb
after_action :log_admin_access

def log_admin_access
  Rails.logger.info("[ADMIN ACCESS] #{current_user} - #{request.method} #{request.path}")
end
```

**Consulter logs** :
```bash
grep "ADMIN ACCESS" log/production.log
```

### D. Pas de robots

L'admin ajoute automatiquement :
```html
<meta name="robots" content="noindex, nofollow">
```

→ Les moteurs de recherche n'indexeront PAS `/admin`

---

## 8. Workflow admin typique

### Ajouter une nouvelle source et vérifier

```
1. Aller sur /admin
2. Cliquer "Nouvelle URL"
3. Remplir formulaire :
   - URL: https://example.com/events
   - Nom: "Example Events"
   - Notes: "Événements dans <section class='events'>"
   - Statut: actif
4. Créer
5. Cliquer "🔄 Scraper maintenant"
6. Attendre 30-60 secondes
7. Recharger la page
8. Vérifier section "10 derniers ChangeLogs"
   - Si vide → Scraping a échoué (voir erreurs_consecutives)
   - Si présent → Voir nombre events créés
9. Aller sur /admin/events
10. Vérifier que les events sont corrects
    - Titres, dates, prix OK ?
    - Professeurs dédupliqués correctement ?
11. Si parsing incorrect :
    - Éditer la ScrapedUrl
    - Améliorer "Notes correctrices"
    - Supprimer les events incorrects (console)
    - Re-scraper
```

### Déboguer un scraping qui échoue

```
1. /admin/scraped_urls/:id
2. Vérifier "Erreurs consécutives" (> 0 = problème)
3. Cliquer "Prévisualiser HTML"
   - HTML est-il chargé ?
   - Structure attendue ?
4. Si HTML vide/404 :
   - URL cassée → Corriger
5. Si HTML OK mais parsing échoue :
   - Améliorer notes correctrices
   - Tester via bin/rails scraping:test[ID] en console
6. Consulter logs Rails :
   tail -f log/development.log | grep scraping_failed
```

---

## 9. URLs admin disponibles

| Route | Description |
|-------|-------------|
| `/admin` | Dashboard (liste ScrapedUrls) |
| `/admin/scraped_urls` | Liste ScrapedUrls |
| `/admin/scraped_urls/new` | Ajouter nouvelle URL |
| `/admin/scraped_urls/:id` | Détails URL |
| `/admin/scraped_urls/:id/edit` | Éditer URL |
| `/admin/scraped_urls/:id/preview` | Prévisualiser HTML |
| `/admin/scraped_urls/:id/scrape_now` | Scraper maintenant (POST) |
| `/admin/scraped_urls/:id/crawl_site` | Crawler le site (POST) |
| `/admin/site_crawls` | Liste des crawls |
| `/admin/site_crawls/:id` | Détail d'un crawl (pages trouvées) |
| `/admin/change_logs` | Liste ChangeLogs |
| `/admin/change_logs/:id` | Détails ChangeLog (diff HTML) |
| `/admin/events` | Liste Events |
| `/admin/events/:id` | Détails Event |
| `/admin/events/:id/edit` | Éditer Event |

---

## 10. Limitations actuelles

### Pas d'interface pour :
- **Gestion Professors** : Pas de CRUD admin pour les profs
  - Solution : Console Rails (`Professor.all`, `Professor.find(1).update(...)`)
- **Gestion Newsletter** : Pas de CRUD admin pour les emails newsletter
  - Solution : Console Rails (`Newsletter.all`)
- **Compteur erreurs** : Pas éditable via formulaire
  - Solution : Console Rails (`scraped_url.update!(erreurs_consecutives: 0)`)
- **Monitoring jobs Solid Queue** : Pas d'interface visuelle
  - Solution : Console Rails (`SolidQueue::Job.all`)

### Évolutions futures possibles :
- Dashboard avec stats (nombre events, profs, sources actives)
- Interface gestion Professors (merge, vérification status)
- Interface gestion Newsletter (export CSV, stats)
- Monitoring Solid Queue intégré
- Logs scraping en temps réel
- Graphiques (events créés par jour, sources les plus actives)

---

## 11. Ressources

- **Guide scraping** : `docs/guide-scraping.md`
- **Architecture technique** : `docs/scraping-architecture.md`
- **Console Rails** : `bin/rails console`
- **Routes disponibles** : `bin/rails routes | grep admin`

---

## Aide rapide (cheatsheet)

```bash
# Accès admin
http://localhost:3002/admin
# Username: admin
# Password: change_me_in_production (CHANGER EN PROD !)

# Changer credentials
nano ~/.env-stopanddance
# ADMIN_USERNAME=...
# ADMIN_PASSWORD=...

# Réinitialiser erreurs (console)
ScrapedUrl.find(ID).update!(erreurs_consecutives: 0)

# Forcer re-scraping (console)
ScrapedUrl.find(ID).update!(derniere_version_html: nil)

# Voir jobs Solid Queue (console)
SolidQueue::Job.where(queue_name: "scraping")

# Voir logs scraping
tail -f log/development.log | grep scraping
```

---

**Dernière mise à jour** : 2026-04-07
**Version** : 2.0 (ajout crawler site)
