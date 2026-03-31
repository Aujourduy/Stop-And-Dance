# Protocole de Vérification du Scraping

Ce document décrit le protocole complet pour vérifier qu'un scraping a fonctionné correctement et que les données extraites sont cohérentes.

## Quand utiliser ce protocole ?

- Après l'ajout d'un nouveau ScrapedUrl
- Après une modification du code de scraping
- Après un parsing Claude sur une nouvelle source
- Quand l'utilisateur demande de vérifier le scraping

---

## 1. Vérifications de Base

### 1.1. Comptage des événements

```sql
SELECT COUNT(*) as total_events
FROM events
WHERE scraped_url_id = :id;
```

**Attendu :** Au moins 1 événement extrait (sinon le scraping a échoué)

### 1.2. Vérification des timestamps ScrapedUrl

```sql
SELECT
  id,
  derniere_version_html_at IS NOT NULL as html_ok,
  derniere_version_markdown_at IS NOT NULL as markdown_ok,
  dernier_parsing_claude_at IS NOT NULL as claude_ok,
  LENGTH(derniere_version_html) as html_size,
  LENGTH(derniere_version_markdown) as markdown_size
FROM scraped_urls
WHERE id = :id;
```

**Attendu :**
- `html_ok = true` (HTML téléchargé)
- `markdown_ok = true` (Markdown généré)
- `claude_ok = true` (Parsing Claude effectué)
- `html_size > 5000` (minimum raisonnable, dépend de la source)
- `markdown_size > 100` (minimum raisonnable)

### 1.3. Vérification change_logs

```sql
SELECT COUNT(*) as nb_change_logs
FROM change_logs
WHERE scraped_url_id = :id;
```

**Attendu :** Au moins 1 change_log créé (tracking des modifications)

---

## 2. Vérifications de Cohérence des Données

### 2.1. Association avec Professor

```sql
SELECT
  COUNT(*) as total,
  COUNT(professor_id) as avec_professor,
  COUNT(*) - COUNT(professor_id) as sans_professor
FROM events
WHERE scraped_url_id = :id;
```

**Attendu :** `sans_professor = 0` (tous les événements doivent avoir un professor)

### 2.2. Cohérence temporelle (dates)

```sql
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE date_fin < date_debut) as dates_inversees,
  COUNT(*) FILTER (WHERE date_debut < NOW() - interval '2 years') as trop_anciens
FROM events
WHERE scraped_url_id = :id;
```

**Attendu :**
- `dates_inversees = 0` (date_fin >= date_debut)
- `trop_anciens = 0` (pas d'événements de plus de 2 ans dans le passé)

### 2.3. Cohérence prix/gratuit

```sql
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE gratuit = true AND (prix_normal IS NOT NULL OR prix_reduit IS NOT NULL)) as incoherent_gratuit,
  COUNT(*) FILTER (WHERE gratuit = false AND prix_normal IS NULL AND prix_reduit IS NULL) as incoherent_payant
FROM events
WHERE scraped_url_id = :id;
```

**Attendu :**
- `incoherent_gratuit = 0` (si gratuit=true, pas de prix)
- `incoherent_payant` peut être > 0 (prix optionnel, information parfois manquante sur le site source)

### 2.4. Données essentielles renseignées

```sql
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE description IS NULL OR description = '') as sans_description,
  COUNT(*) FILTER (WHERE adresse_complete IS NULL OR adresse_complete = '') as sans_adresse,
  COUNT(*) FILTER (WHERE tags IS NULL OR tags = '{}') as sans_tags
FROM events
WHERE scraped_url_id = :id;
```

**Attendu :**
- `sans_description = 0` (description requise)
- `sans_adresse` acceptable selon la source (événements en ligne)
- `sans_tags = 0` (tags générés par Claude)

### 2.5. Vérification doublons

```sql
SELECT titre, COUNT(*) as count
FROM events
WHERE scraped_url_id = :id
GROUP BY titre
HAVING COUNT(*) > 1;
```

**Attendu :** 0 résultats (pas de doublons exacts). Si doublons détectés, analyser pourquoi (variations HTML, erreur parsing Claude).

---

## 3. Comparaison avec le Site Source

### 3.1. Extraction des dates du HTML scraped

```ruby
bin/rails runner "
scraped_url = ScrapedUrl.find(:id)
html = scraped_url.derniere_version_html

require 'nokogiri'
doc = Nokogiri::HTML(html)

events_text = []
doc.css('span, p, div').each do |element|
  text = element.text.strip
  # Chercher patterns de dates
  if text.match?(/\d{1,2}\s+(janvier|février|mars|avril|mai|juin|juillet|août|septembre|octobre|novembre|décembre)/i) && text.length < 200
    events_text << text
  end
end

puts \"Événements trouvés dans le HTML (#{events_text.uniq.length} uniques) :\"
events_text.uniq.first(15).each { |e| puts \"- #{e}\" }
"
```

**Attendu :** Extraire 10-20 événements du HTML (dépend de la source)

### 3.2. Liste des événements en base (même période)

```sql
SELECT
  titre,
  TO_CHAR(date_debut, 'DD/MM/YYYY') as date_debut,
  TO_CHAR(date_fin, 'DD/MM/YYYY') as date_fin,
  lieu,
  prix_normal,
  prix_reduit
FROM events
WHERE scraped_url_id = :id
  AND date_debut >= NOW()
  AND date_debut <= NOW() + interval '6 months'
ORDER BY date_debut
LIMIT 20;
```

**Attendu :** Comparer manuellement avec les dates extraites du HTML

### 3.3. Correspondance dates HTML → DB

**Manuel :** Pour chaque date trouvée dans le HTML, vérifier qu'un événement correspondant existe en DB :

| Date HTML | Événement DB | Statut |
|-----------|--------------|--------|
| 3 avril   | Vague du 3 avril | ✅ |
| 4-5 avril | SILLAGES 04-05/04 | ✅ |

**Objectif :** Minimum 80% de correspondance (certaines dates peuvent être ambiguës dans le HTML)

---

## 4. Vérifications d'Affichage

### 4.1. Affichage public (site utilisateur)

```bash
curl -s http://localhost:3002/evenements | grep -A 5 "titre_event_1\|titre_event_2" | head -30
```

**Attendu :** Les événements s'affichent correctement dans le HTML généré

### 4.2. Affichage admin (preview)

```bash
curl -s -u admin:password http://localhost:3002/admin/scraped_urls/:id/preview | grep -i "événements parsés"
```

**Attendu :** Page preview affiche les événements + timestamps + iframe HTML

### 4.3. Test iframe HTML brut

```bash
curl -s -u admin:password http://localhost:3002/admin/scraped_urls/:id/raw_html | head -100
```

**Attendu :** Retourne le HTML brut de la source (pour debug visuel)

---

## 5. Vérifications Avancées

### 5.1. Échantillon détaillé d'événements

```sql
SELECT
  titre,
  lieu,
  adresse_complete,
  prix_normal,
  prix_reduit,
  gratuit,
  type_event,
  substring(description from 1 for 100) as desc_preview,
  tags
FROM events
WHERE scraped_url_id = :id
ORDER BY RANDOM()
LIMIT 5;
```

**Attendu :** Vérifier manuellement la cohérence des données (lieu, prix, description, tags)

### 5.2. Distribution des types d'événements

```sql
SELECT
  type_event,
  COUNT(*) as count
FROM events
WHERE scraped_url_id = :id
GROUP BY type_event;
```

**Attendu :** Distribution raisonnable (0=cours, 1=stage, 2=événement)

### 5.3. Distribution temporelle

```sql
SELECT
  TO_CHAR(date_debut, 'YYYY-MM') as mois,
  COUNT(*) as nb_events
FROM events
WHERE scraped_url_id = :id
GROUP BY TO_CHAR(date_debut, 'YYYY-MM')
ORDER BY mois;
```

**Attendu :** Distribution cohérente avec la source (certains mois peuvent avoir plus d'événements)

---

## 6. Checklist Finale

Avant de valider le scraping, vérifier :

- [ ] ✅ Au moins 1 événement extrait
- [ ] ✅ Tous les timestamps renseignés (HTML, Markdown, Claude)
- [ ] ✅ Tailles HTML/Markdown raisonnables
- [ ] ✅ Tous les events ont un professor_id
- [ ] ✅ Pas de dates incohérentes (fin < début)
- [ ] ✅ Pas d'incohérence prix/gratuit majeure
- [ ] ✅ Descriptions renseignées
- [ ] ✅ Tags renseignés
- [ ] ✅ Au moins 1 change_log créé
- [ ] ✅ Correspondance dates HTML vs DB (≥ 80%)
- [ ] ✅ Affichage site public OK
- [ ] ✅ Affichage admin preview OK

---

## 7. En Cas de Problème

### Problème : 0 événements extraits

**Diagnostic :**
1. Vérifier HTML téléchargé : `SELECT LENGTH(derniere_version_html) FROM scraped_urls WHERE id = :id`
2. Vérifier Markdown : `SELECT LENGTH(derniere_version_markdown) FROM scraped_urls WHERE id = :id`
3. Vérifier logs Claude : `tail -100 log/development.log | grep Claude`

**Solutions possibles :**
- HTML vide → vérifier `use_browser=true` si site JavaScript
- Markdown vide → problème HtmlCleaner
- Parsing Claude échoué → vérifier `notes_correctrices`, relancer parsing

### Problème : Doublons détectés

**Diagnostic :**
```sql
SELECT titre, date_debut, COUNT(*)
FROM events
WHERE scraped_url_id = :id
GROUP BY titre, date_debut
HAVING COUNT(*) > 1;
```

**Solutions possibles :**
- Variations de titre dans HTML → ajouter déduplication dans Claude prompt
- Erreur parsing → corriger `notes_correctrices`

### Problème : Données manquantes (prix, adresses, etc.)

**Diagnostic :** Vérifier si l'info existe dans le HTML source

**Solutions possibles :**
- Info absente du HTML → normal, accepter NULL
- Info présente mais non extraite → améliorer `notes_correctrices` pour Claude

### Problème : Timestamps ne se mettent pas à jour

**Diagnostic :** Vérifier controller utilise `assign_attributes` + `save!(touch: false)`

**Solution :** Voir commit `f681991` - force update timestamp même si contenu identique

---

## 8. Commandes Rapides (Copier-Coller)

```bash
# Vérification complète d'un ScrapedUrl (remplacer :id)
SCRAPED_URL_ID=7

# 1. Base
psql -U dang -d stopanddance_development -c "SELECT COUNT(*) FROM events WHERE scraped_url_id = $SCRAPED_URL_ID;"

# 2. Timestamps
psql -U dang -d stopanddance_development -c "SELECT derniere_version_html_at, derniere_version_markdown_at, dernier_parsing_claude_at FROM scraped_urls WHERE id = $SCRAPED_URL_ID;"

# 3. Cohérence dates
psql -U dang -d stopanddance_development -c "SELECT COUNT(*) FILTER (WHERE date_fin < date_debut) as dates_inversees FROM events WHERE scraped_url_id = $SCRAPED_URL_ID;"

# 4. Affichage site
curl -s http://localhost:3002/evenements | grep -A 3 "titre" | head -20

# 5. Échantillon événements
psql -U dang -d stopanddance_development -c "SELECT titre, lieu, prix_normal, TO_CHAR(date_debut, 'DD/MM/YYYY') FROM events WHERE scraped_url_id = $SCRAPED_URL_ID ORDER BY date_debut LIMIT 10;"
```

---

## Notes

- Ce protocole a été créé suite à la vérification du scraping de Marc Silvestre (ScrapedUrl #7)
- Les seuils (80% correspondance, tailles min, etc.) peuvent être ajustés selon les sources
- Automatiser ces vérifications dans un script `bin/verify-scraping.rb` si utilisé fréquemment
