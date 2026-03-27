# Guide Utilisateur — Scraping Stop & Dance

Guide pratique pour ajouter des sources, lancer le scraping et vérifier les résultats.

---

## Table des matières

1. [Ajouter une URL à scraper](#1-ajouter-une-url-à-scraper)
2. [Lancer le scraping](#2-lancer-le-scraping)
3. [Vérifier les résultats](#3-vérifier-les-résultats)
4. [Commandes utiles](#4-commandes-utiles)
5. [Workflow complet (exemple)](#5-workflow-complet-exemple)
6. [Debugging](#6-debugging)
7. [Scraping automatique 24h](#7-scraping-automatique-24h)
8. [Notes correctrices](#8-notes-correctrices)

---

## 1. Ajouter une URL à scraper

### Méthode A : Console Rails (recommandé pour tester)

```bash
# Ouvrir console Rails
bin/rails console
```

```ruby
# Créer une nouvelle URL
ScrapedUrl.create!(
  url: "https://danse-contact-paris.fr/agenda",
  nom: "Agenda Danse Contact Paris",
  notes_correctrices: "Planning mensuel - format HTML classique",
  statut_scraping: "actif"
)

# Ou avec find_or_create_by (évite doublons)
ScrapedUrl.find_or_create_by!(url: "https://example.com/events") do |su|
  su.nom = "Nom descriptif du site"
  su.notes_correctrices = "Instructions spécifiques pour Claude"
  su.statut_scraping = "actif"
end

# Quitter console
exit
```

**Champs** :
- `url` (requis) : URL complète à scraper
- `nom` (optionnel) : Label lisible pour l'admin (ex: "Site de Marie Dupont")
- `notes_correctrices` (optionnel) : Instructions pour aider Claude à parser (voir section 8)
- `statut_scraping` : `"actif"` ou `"inactif"`

### Méthode B : Éditer les seeds (pour permanence)

```ruby
# Éditer db/seeds.rb
scraped_urls_data = [
  # ... existants ...
  {
    url: "https://votre-nouveau-site.com/agenda",
    nom: "Nom descriptif",
    notes_correctrices: "Instructions parsing"
  }
]
```

Puis relancer :
```bash
bin/rails db:seed
```

---

## 2. Lancer le scraping

### A. Test (dry-run) — Ne sauvegarde RIEN

**Parfait pour tester une nouvelle URL avant scraping réel.**

```bash
# 1. Lister les URLs disponibles
bin/rails runner "ScrapedUrl.all.each { |s| puts \"#{s.id}: #{s.nom || s.url}\" }"

# 2. Tester le scraping (remplacer 1 par l'ID)
bin/rails scraping:test[1]
```

**Résultat affiché** :
```
=== DRY-RUN TEST: https://example.com/sophie-marchand ===
Notes correctrices: Site personnel - scraping actif

Fetching HTML...
HTML fetched (12345 bytes)

Parsing with Claude CLI...

Parsed 3 event(s):

--- Event 1 ---
Titre: Atelier Contact Improvisation
Date début: 2026-03-29T19:30:00+01:00
Date fin: 2026-03-29T21:30:00+01:00
Lieu: Paris
Prix: 20.0€
Type: atelier
Tags: Contact Improvisation

...

=== DRY-RUN COMPLETED (no DB changes) ===
```

### B. Scraping réel — Sauvegarde en DB

```bash
# Scraper UNE URL spécifique
bin/rails scraping:run[1]  # Remplacer 1 par l'ID

# Scraper TOUTES les URLs actives
bin/rails scraping:run_all
```

**Ce qui se passe** :
1. Fetch HTML de l'URL
2. Compare avec `derniere_version_html` (via HtmlDiffer)
3. **Si inchangé** → Skip parsing (économie appels Claude)
4. **Si changé** :
   - Crée ChangeLog avec diff HTML
   - Parse avec Claude CLI
   - Crée/met à jour professeurs (déduplication auto)
   - Crée/met à jour événements
   - Reset `erreurs_consecutives` à 0

---

## 3. Vérifier les résultats

### A. Vérifier les événements créés

```bash
bin/rails console
```

```ruby
# Derniers events créés
Event.order(created_at: :desc).limit(5).each do |e|
  puts "#{e.titre} - #{e.date_debut.strftime('%d/%m/%Y %H:%M')}"
  puts "  Prof: #{e.professor.nom}"
  puts "  Source: #{e.scraped_url&.nom || 'Manuel'}"
  puts "  Prix: #{e.prix_normal}€#{e.gratuit ? ' (GRATUIT)' : ''}"
  puts
end

# Events d'une source spécifique
scraped_url = ScrapedUrl.find_by(nom: "Agenda Danse Contact Paris")
puts "#{scraped_url.nom}: #{scraped_url.events.count} événements"
scraped_url.events.each do |e|
  puts "  - #{e.titre} (#{e.professor.nom})"
end

# Compter events par source
ScrapedUrl.where(statut_scraping: "actif").each do |s|
  puts "#{s.nom || s.url}: #{s.events.count} événements"
end
```

### B. Vérifier les professeurs (déduplication)

```ruby
# Lister tous les profs
Professor.all.each do |p|
  puts "#{p.nom} (#{p.status})"
  puts "  Sources: #{p.scraped_urls.pluck(:nom).join(', ')}"
  puts "  Events: #{p.events.count}"
  puts
end

# Vérifier qu'un prof n'a PAS été dupliqué
Professor.where("nom_normalise LIKE ?", "%marie%").each do |p|
  puts "#{p.nom} (normalise: #{p.nom_normalise})"
end

# Test déduplication manuelle
prof = Professor.find_or_create_from_scrape(nom: "  MARIE   DUPONT  ")
puts "Prof trouvé/créé: #{prof.nom} (ID #{prof.id})"
# → Si existait déjà, retourne l'existant (pas de doublon)
```

### C. Vérifier l'historique des changements

```ruby
# Derniers changements HTML détectés
ChangeLog.order(created_at: :desc).limit(5).each do |log|
  puts "#{log.created_at.strftime('%d/%m/%Y %H:%M')} - #{log.scraped_url.nom}"
  puts "  Lignes ajoutées: #{log.changements_detectes['lines_added']}"
  puts "  Lignes supprimées: #{log.changements_detectes['lines_removed']}"
  puts
end

# Voir le diff HTML complet d'un ChangeLog
log = ChangeLog.last
puts log.diff_html  # Diff ligne par ligne (format HTML)
```

### D. Vérifier les erreurs

```ruby
# URLs avec erreurs récentes
ScrapedUrl.where("erreurs_consecutives > 0").each do |s|
  puts "⚠️  #{s.nom || s.url}: #{s.erreurs_consecutives} erreur(s) consécutive(s)"
end

# Détails dernière erreur (dans logs Rails)
# Chercher dans log/development.log ou log/production.log
# Grep "scraping_failed" pour voir les erreurs
```

---

## 4. Commandes utiles

### Lister toutes les URLs

```bash
bin/rails runner "
ScrapedUrl.all.each do |s|
  puts \"#{s.id}: #{s.nom || s.url} (#{s.statut_scraping})\"
  puts \"   Dernière maj: #{s.updated_at.strftime('%d/%m/%Y %H:%M')}\"
  puts \"   Erreurs consécutives: #{s.erreurs_consecutives}\" if s.erreurs_consecutives > 0
  puts \"   Events: #{s.events.count}\"
  puts
end
"
```

### Réinitialiser compteur erreurs

```bash
bin/rails console
```

```ruby
scraped_url = ScrapedUrl.find(1)
scraped_url.update!(erreurs_consecutives: 0)
```

### Désactiver temporairement une URL

```ruby
scraped_url = ScrapedUrl.find_by(nom: "Site problématique")
scraped_url.update!(statut_scraping: "inactif")
# Le scraping automatique 24h la passera désormais
```

### Réactiver une URL

```ruby
scraped_url = ScrapedUrl.find_by(nom: "Site problématique")
scraped_url.update!(statut_scraping: "actif")
```

### Forcer un re-scraping (même si HTML inchangé)

```ruby
# Utile si tu veux forcer une nouvelle analyse
scraped_url = ScrapedUrl.find(1)
scraped_url.update!(derniere_version_html: nil)
# Le prochain scraping détectera forcément un changement
```

### Supprimer tous les events d'une source

```ruby
# Attention : destructif !
scraped_url = ScrapedUrl.find(1)
scraped_url.events.destroy_all
```

### Voir le HTML actuellement stocké

```ruby
scraped_url = ScrapedUrl.find(1)
puts scraped_url.derniere_version_html[0..1000]  # Premiers 1000 caractères
```

---

## 5. Workflow complet (exemple)

```bash
# ============================================
# Étape 1 : Ajouter une nouvelle URL
# ============================================
bin/rails console
```

```ruby
ScrapedUrl.create!(
  url: "https://calendrier.danse-contact.fr/events",
  nom: "Calendrier CI France",
  notes_correctrices: "Format calendrier - extraire titre, date, lieu, prix",
  statut_scraping: "actif"
)
# => Retourne l'objet créé avec son ID (ex: #<ScrapedUrl id: 7, ...>)

exit
```

```bash
# ============================================
# Étape 2 : Tester le scraping (dry-run)
# ============================================
bin/rails scraping:test[7]  # Remplacer 7 par l'ID créé

# Vérifier que le parsing fonctionne
# Si erreur HTTP 404 → URL incorrecte
# Si erreur Claude CLI → Vérifier auth ou format HTML
# Si parsing OK → Passer à l'étape 3

# ============================================
# Étape 3 : Lancer le scraping réel
# ============================================
bin/rails scraping:run[7]

# ============================================
# Étape 4 : Vérifier les résultats
# ============================================
bin/rails console
```

```ruby
# Vérifier events créés
scraped_url = ScrapedUrl.find(7)
puts "Events créés: #{scraped_url.events.count}"
scraped_url.events.last(3).each { |e| puts "  - #{e.titre}" }

# Vérifier profs créés/trouvés
scraped_url.events.map(&:professor).uniq.each do |p|
  puts "Prof: #{p.nom} (status: #{p.status})"
end

# Vérifier ChangeLog
ChangeLog.where(scraped_url: scraped_url).last.changements_detectes

exit
```

---

## 6. Debugging

### Problème : Scraping échoue (HTTP 404, timeout...)

```bash
# Tester fetch manuel
bin/rails runner "
url = 'https://votre-url.com'
result = Scrapers::HtmlScraper.fetch(url)
if result[:error]
  puts '❌ Erreur: ' + result[:error]
else
  puts '✅ HTML fetché: ' + result[:html].size.to_s + ' bytes'
  puts result[:html][0..500]  # Premiers 500 chars
end
"
```

**Solutions** :
- HTTP 404 : URL incorrecte ou page supprimée
- Timeout : Site trop lent (augmenter timeout dans `html_scraper.rb`)
- `Disallowed by robots.txt` : Site bloque les bots (vérifier robots.txt)

### Problème : Claude CLI ne parse rien ou plante

```bash
# Vérifier auth Claude CLI
ls -la ~/.claude/.credentials.json
# Si absent → Se reconnecter : claude auth login

# Tester Claude CLI manuellement
echo "Parse cette liste: Atelier CI Paris, 25 mars 2026, 20€" | claude

# Vérifier timeout
# Si Claude prend > 60s → Augmenter TIMEOUT_SECONDS dans claude_cli_integration.rb
```

### Problème : HTML détecté comme inchangé alors qu'il a changé

```ruby
# Console Rails
scraped_url = ScrapedUrl.find(1)

# Voir HTML stocké vs HTML actuel
puts "HTML stocké (premiers 500 chars):"
puts scraped_url.derniere_version_html[0..500]

# Fetch HTML actuel
result = Scrapers::HtmlScraper.fetch(scraped_url.url)
puts "\nHTML actuel (premiers 500 chars):"
puts result[:html][0..500]

# Comparer manuellement
# Si identiques → Normal (pas de changement)
# Si différents → Problème de normalisation HtmlDiffer
```

**Solution** : Forcer nouveau scraping
```ruby
scraped_url.update!(derniere_version_html: nil)
```

### Problème : Professeurs dupliqués malgré déduplication

```ruby
# Trouver doublons
Professor.group(:nom_normalise).having("COUNT(*) > 1").count
# => Si résultat, il y a des doublons (ne devrait jamais arriver)

# Merger manuellement
doublon = Professor.find(2)
principal = Professor.find(1)

# Réassocier events du doublon
doublon.events.update_all(professor_id: principal.id)

# Supprimer doublon
doublon.destroy
```

### Problème : Events en double

```ruby
# Trouver events similaires
Event.where(titre: "Atelier CI Paris").where("date_debut::date = ?", Date.parse("2026-03-29"))

# Si plusieurs → Supprimer les doublons
# Garder le plus récent, supprimer les autres
events = Event.where(titre: "...", date_debut: ...)
events.order(created_at: :asc).limit(events.count - 1).destroy_all
```

---

## 7. Scraping automatique 24h

Le scraping automatique se lance toutes les 24h via `ScrapingDispatchJob` (Solid Queue).

### Vérifier que le job automatique tourne

```bash
bin/rails console
```

```ruby
# Voir les jobs Solid Queue en attente
SolidQueue::Job.where(queue_name: "scraping").count

# Voir les jobs en échec
SolidQueue::FailedExecution.last(5)

# Enqueuer manuellement le job dispatch
ScrapingDispatchJob.perform_later
```

### Configuration du cron 24h

**Fichier** : `config/recurring.yml` (si existe) ou dans `config/initializers/solid_queue.rb`

```yaml
# Exemple configuration
scraping_dispatch:
  class: ScrapingDispatchJob
  queue: scraping
  schedule: "0 2 * * *"  # Tous les jours à 2h du matin
```

### Désactiver le scraping automatique temporairement

```ruby
# Mettre toutes les URLs en inactif
ScrapedUrl.update_all(statut_scraping: "inactif")

# Ou juste quelques-unes
ScrapedUrl.where(id: [1, 2, 3]).update_all(statut_scraping: "inactif")
```

---

## 8. Notes correctrices

Les **notes correctrices** aident Claude à parser des HTML complexes ou mal structurés.

### Quand les utiliser ?

- HTML non-sémantique (tables imbriquées, divs sans classes)
- Format inhabituel (prix dans plusieurs endroits, dates ambiguës)
- Besoin d'ignorer certaines sections
- Multi-langues (préciser la langue attendue)

### Exemples de notes correctrices

```ruby
# Exemple 1 : Structure HTML précise
notes_correctrices: "Les événements sont dans <div class='event-card'>.
Le titre est dans <h3 class='title'>.
Le prix est dans <span class='price'> (format: '20€' ou 'Gratuit').
Ignorer les événements avec class 'past'."

# Exemple 2 : Format date spécifique
notes_correctrices: "Les dates sont au format français 'jj/mm/aaaa HH:MM'.
Si seule l'heure est indiquée, la date est celle du premier <h2>."

# Exemple 3 : Multi-profs
notes_correctrices: "Plusieurs professeurs par event (liste séparée par ',').
Créer un event par professeur si co-animation."

# Exemple 4 : Prix complexe
notes_correctrices: "Prix dans format 'Tarif plein: 25€ / Tarif réduit: 18€'.
Extraire les deux tarifs."

# Exemple 5 : Tags spécifiques
notes_correctrices: "Les tags de danse sont dans <span class='dance-style'>.
Toujours ajouter le tag 'Contact Improvisation' même si non mentionné (site spécialisé)."
```

### Tester l'impact des notes correctrices

```bash
# Sans notes
bin/rails runner "
su = ScrapedUrl.find(1)
su.update!(notes_correctrices: nil)
"
bin/rails scraping:test[1]

# Avec notes
bin/rails runner "
su = ScrapedUrl.find(1)
su.update!(notes_correctrices: 'Les événements sont dans <article class=event>')
"
bin/rails scraping:test[1]

# Comparer les résultats
```

---

## 9. Commandes de maintenance

### Nettoyer les events passés (optionnel)

```bash
bin/rails console
```

```ruby
# Supprimer events passés depuis > 30 jours
Event.where("date_fin < ?", 30.days.ago).destroy_all

# Ou juste les compter
Event.where("date_fin < ?", 30.days.ago).count
```

### Réinitialiser toutes les URLs (fresh start)

```ruby
# ATTENTION : Destructif !
ScrapedUrl.all.each do |su|
  su.update!(
    derniere_version_html: nil,
    erreurs_consecutives: 0
  )
end

# Puis relancer scraping
bin/rails scraping:run_all
```

### Exporter les events en JSON

```bash
bin/rails runner "
events = Event.futurs.includes(:professor, :scraped_url)
File.write('tmp/events_export.json', events.to_json(
  include: { professor: { only: [:nom, :email] } },
  only: [:titre, :date_debut, :date_fin, :lieu, :prix_normal]
))
puts 'Exported to tmp/events_export.json'
"
```

---

## 10. Checklist avant production

- [ ] Toutes les URLs de test (`example.com`) remplacées par vraies URLs
- [ ] Claude CLI authentifié : `ls ~/.claude/.credentials.json`
- [ ] Au moins 3 URLs actives testées avec `scraping:test`
- [ ] Déduplication testée : créer 2 events avec même prof (noms légèrement différents)
- [ ] ChangeLog fonctionne : vérifier `ChangeLog.count` après scraping
- [ ] Scraping automatique 24h configuré (Solid Queue + cron)
- [ ] Alertes email configurées (3 erreurs consécutives → email admin)
- [ ] Backup DB quotidien activé (rétention 30 jours)

---

## 11. Ressources

- **Architecture technique** : `docs/scraping-architecture.md`
- **Logs scraping** : `log/development.log` ou `log/production.log`
- **Console Rails** : `bin/rails console`
- **Tests unitaires** : `bin/rails test test/models/professor_test.rb`
- **Rake tasks** : `bin/rails -T scraping` (liste toutes les tasks scraping)

---

## Aide rapide (cheatsheet)

```bash
# Lister URLs
bin/rails runner "ScrapedUrl.all.each { |s| puts \"#{s.id}: #{s.nom}\" }"

# Test scraping (dry-run)
bin/rails scraping:test[ID]

# Scraping réel
bin/rails scraping:run[ID]

# Scraper toutes les URLs actives
bin/rails scraping:run_all

# Console Rails
bin/rails console

# Derniers events
Event.last(5)

# Derniers changeLogs
ChangeLog.last(5)

# URLs avec erreurs
ScrapedUrl.where("erreurs_consecutives > 0")

# Réinitialiser erreurs
ScrapedUrl.find(ID).update!(erreurs_consecutives: 0)

# Forcer re-scraping
ScrapedUrl.find(ID).update!(derniere_version_html: nil)
```

---

**Dernière mise à jour** : 2026-03-27
**Version** : 1.0
