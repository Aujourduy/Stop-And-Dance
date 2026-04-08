---
title: 'Gestion des événements récurrents dans le parsing'
slug: 'recurrence-events'
created: '2026-04-08'
status: 'ready-for-dev'
---

# Quick-Spec : Gestion des événements récurrents

## Problème

Actuellement, quand un site mentionne "tous les vendredis 19h30-21h30" (Marc Silvestre) ou "2 mercredis par mois" avec des dates listées (Peter Wilberforce), Claude retourne un seul event générique. On veut un event individuel par date.

## Deux cas à gérer

### Cas 1 : Dates explicites (Peter Wilberforce)
Le site liste les dates : "12 avril, 26 avril, 10 mai, 24 mai..."
→ Claude extrait chaque date → un event par date. **Pas de calcul côté Rails.**

### Cas 2 : Récurrence calculée (Marc Silvestre)
Le site dit "tous les vendredis 19h30-21h30" sans lister les dates.
→ Claude retourne la règle de récurrence → **Rails calcule et génère** les events individuels de aujourd'hui jusqu'au 31 août.

### Cas 3 : Exclusions (Marc Silvestre)
Le site dit "tous les vendredis SAUF le 18 avril et le 2 mai" ou "pas de cours du 15 au 30 juillet".
→ Claude extrait les exclusions → Rails les retire du calcul.

## Solution

### Étape 1 : Modifier le schéma JSON de sortie Claude

Ajouter des champs optionnels dans la réponse JSON :

```json
{
  "events": [
    {
      "titre": "Vagues du matin",
      "professor_nom": "Marc Silvestre",
      "date_debut": "2026-04-11T19:30:00+02:00",
      "date_fin": "2026-04-11T21:30:00+02:00",
      "lieu": "Paris",
      "prix_normal": 20.00,
      "recurrence": null
    }
  ]
}
```

**Si dates explicites** (cas 1) : Claude retourne N events séparés, chacun avec sa date. Pas de champ `recurrence`. C'est le comportement souhaité.

**Si récurrence calculée** (cas 2+3) : Claude retourne UN seul event template avec `recurrence` :

```json
{
  "titre": "Vagues - Session du soir",
  "professor_nom": "Marc Silvestre",
  "date_debut": "2026-04-11T19:30:00+02:00",
  "date_fin": "2026-04-11T21:30:00+02:00",
  "lieu": "Paris",
  "prix_normal": 20.00,
  "recurrence": {
    "type": "weekly",
    "day_of_week": "friday",
    "time_start": "19:30",
    "time_end": "21:30",
    "excluded_dates": ["2026-04-18", "2026-05-02"],
    "excluded_ranges": [
      {"from": "2026-07-15", "to": "2026-07-30"}
    ]
  }
}
```

### Étape 2 : Modifier le prompt Claude CLI

Dans `lib/claude_cli_integration.rb`, ajouter au prompt :

```
RÈGLES POUR LES ÉVÉNEMENTS RÉCURRENTS :

1. Si le site LISTE des dates explicites (ex: "12 avril, 26 avril, 10 mai") :
   → Crée UN event séparé pour CHAQUE date. Pas de champ "recurrence".

2. Si le site dit "tous les [jour]" ou "chaque [jour]" SANS lister les dates :
   → Crée UN SEUL event template avec le champ "recurrence" :
   {
     "recurrence": {
       "type": "weekly",
       "day_of_week": "monday|tuesday|wednesday|thursday|friday|saturday|sunday",
       "time_start": "HH:MM",
       "time_end": "HH:MM",
       "excluded_dates": ["YYYY-MM-DD", ...],
       "excluded_ranges": [{"from": "YYYY-MM-DD", "to": "YYYY-MM-DD"}, ...]
     }
   }

3. Si le site mentionne des EXCEPTIONS ("sauf le...", "pas de cours le...", "vacances du...au...") :
   → Les mettre dans excluded_dates (dates isolées) ou excluded_ranges (périodes).

4. Si le site dit "2 fois par mois" avec les dates listées → cas 1 (dates explicites).
```

### Étape 3 : Service `RecurrenceExpander`

Nouveau service `lib/recurrence_expander.rb` :

```ruby
class RecurrenceExpander
  # Période : aujourd'hui → 31 août de l'année en cours
  # Si on est après le 31 août, aller jusqu'au 31 août de l'année suivante
  END_MONTH = 8   # août
  END_DAY = 31

  def self.expand(event_data)
    recurrence = event_data["recurrence"]
    return [event_data] if recurrence.nil?

    end_date = calculate_end_date
    start_date = Date.current

    day_number = Date::DAYNAMES.index(recurrence["day_of_week"].capitalize)
    return [event_data] if day_number.nil?

    excluded = build_excluded_set(recurrence)

    dates = []
    current = start_date
    # Avancer au prochain jour correspondant
    current += 1 until current.wday == day_number

    while current <= end_date
      dates << current unless excluded.include?(current)
      current += 7
    end

    # Générer un event par date
    dates.map do |date|
      event = event_data.except("recurrence")
      event["date_debut"] = "#{date}T#{recurrence['time_start']}:00+02:00"
      event["date_fin"] = "#{date}T#{recurrence['time_end']}:00+02:00"
      event
    end
  end

  private

  def self.calculate_end_date
    today = Date.current
    end_date = Date.new(today.year, END_MONTH, END_DAY)
    end_date = Date.new(today.year + 1, END_MONTH, END_DAY) if today > end_date
    end_date
  end

  def self.build_excluded_set(recurrence)
    excluded = Set.new

    (recurrence["excluded_dates"] || []).each do |d|
      excluded.add(Date.parse(d)) rescue nil
    end

    (recurrence["excluded_ranges"] || []).each do |range|
      from = Date.parse(range["from"]) rescue next
      to = Date.parse(range["to"]) rescue next
      (from..to).each { |d| excluded.add(d) }
    end

    excluded
  end
end
```

### Étape 4 : Modifier `EventUpdateJob`

Dans `app/jobs/event_update_job.rb`, après le parsing Claude, avant la création des events :

```ruby
# Expand recurring events
expanded_events = parsed_events.flat_map { |e| RecurrenceExpander.expand(e) }

# Create/update events from expanded list
expanded_events.each do |event_data|
  # ... existing creation logic ...
end
```

## Fichiers à modifier

| Fichier | Action |
|---------|--------|
| `lib/claude_cli_integration.rb` | Ajouter règles récurrence au prompt + champ `recurrence` au schéma JSON |
| `lib/recurrence_expander.rb` | **Nouveau** — expand weekly → dates individuelles |
| `app/jobs/event_update_job.rb` | Appeler `RecurrenceExpander.expand` avant création events |
| `test/lib/recurrence_expander_test.rb` | **Nouveau** — tests unitaires |

## Acceptance Criteria

- [ ] **AC 1** : Given un site avec "tous les vendredis 19h30-21h30", when Claude parse, then il retourne 1 event avec `recurrence.type=weekly, day_of_week=friday`. EventUpdateJob crée N events individuels (un par vendredi jusqu'au 31 août).

- [ ] **AC 2** : Given un site avec dates listées "12 avril, 26 avril, 10 mai", when Claude parse, then il retourne 3 events séparés sans champ `recurrence`. Pas de calcul Rails.

- [ ] **AC 3** : Given un event récurrent "tous les vendredis sauf le 18 avril", when RecurrenceExpander.expand, then le 18 avril n'a pas d'event généré.

- [ ] **AC 4** : Given un event récurrent avec exclusion de période "vacances du 15 au 30 juillet", when RecurrenceExpander.expand, then aucun event généré entre le 15 et le 30 juillet.

- [ ] **AC 5** : Given la date du jour est le 8 avril 2026, when RecurrenceExpander.expand pour "tous les vendredis", then le premier event est le 11 avril 2026 (prochain vendredi) et le dernier le 28 août 2026 (dernier vendredi avant le 31 août).

- [ ] **AC 6** : Given un event sans champ `recurrence` (cas normal), when RecurrenceExpander.expand, then retourne l'event tel quel (pass-through).

- [ ] **AC 7** : Given un re-scraping du même site, when les events récurrents sont régénérés, then pas de doublons (déduplication par scraped_url_id + date_debut + titre existante).

## Notes

- **Timezone** : les heures sont en Europe/Paris (+02:00 été, +01:00 hiver). Le RecurrenceExpander doit utiliser le bon offset selon la date.
- **Période** : aujourd'hui → 31 août. Si on est après le 31 août → 31 août année suivante.
- **Déduplication** : `EventUpdateJob` utilise déjà `find_or_initialize_by(scraped_url_id, date_debut, titre)`. Ça protège contre les doublons lors des re-scrapings.
- **Risque** : Claude peut mal interpréter "tous les vendredis" vs "les vendredis en avril". Le prompt doit être très explicite.
- **Volume** : un cours hebdomadaire sur 5 mois = ~21 events. Raisonnable.
