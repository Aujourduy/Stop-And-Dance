# Checklist Tests — Récurrence Events

Cocher chaque item après validation.

---

## 1. Tests unitaires (automatisés)

- [ ] `bin/rails test test/lib/recurrence_expander_test.rb` — 8 tests, 0 failures
- [ ] `bin/rails test` — tous les tests passent (97 runs, 0 failures)

## 2. Test Marc Silvestre (récurrence weekly)

**Prérequis :** ScrapedUrl #7 avec HTML en cache

- [ ] Lancer le parsing : `bin/rails runner "EventUpdateJob.perform_now(7)"`
- [ ] Vérifier les events créés : `bin/rails runner "puts Event.where(scraped_url_id: 7).count"`
- [ ] Vérifier qu'il y a ~20 events "Vagues" (vendredis weekly)
- [ ] Vérifier que le premier vendredi est >= aujourd'hui
- [ ] Vérifier que le dernier vendredi est <= 31 août 2026
- [ ] Vérifier que le 3 avril 2026 (studio Noces) n'a PAS de "Vagues" weekly mais a un event "Vague du 3 avril - Studio Noces"
- [ ] Vérifier que le 12 juin 2026 (studio Noces) n'a PAS de "Vagues" weekly mais a un event "Vague du 12 juin - Studio Noces"
- [ ] Vérifier qu'il y a des stages (Rennes, Ardèche, Soulac, etc.) avec dates uniques
- [ ] Vérifier sur /evenements que les vendredis de Marc apparaissent chaque semaine

## 3. Test Peter Wilberforce (dates explicites + 1 weekly)

**Prérequis :** ScrapedUrl #9 avec HTML en cache

- [ ] Lancer le parsing : `bin/rails runner "EventUpdateJob.perform_now(9)"`
- [ ] Vérifier les events créés : `bin/rails runner "puts Event.where(scraped_url_id: 9).count"`
- [ ] Vérifier "Wednesday Waves" : ~20 events avec dates individuelles (pas de recurrence weekly)
- [ ] Vérifier "Le Corps de la Danse" : ~19 events mardis (recurrence weekly expandée)
- [ ] Vérifier "Quand le Corps Vous Danse" : ~9 events (dates mensuelles explicites)
- [ ] Vérifier les stages (Gravité, Ici et Maintenant, Toucher la Terre, etc.)
- [ ] Vérifier sur /evenements que les ateliers de Peter apparaissent aux bonnes dates

## 4. Pas de doublons au re-scraping

- [ ] Relancer `EventUpdateJob.perform_now(7)` une 2ème fois
- [ ] Vérifier que le nombre d'events n'a PAS doublé (même count qu'avant)
- [ ] Relancer `EventUpdateJob.perform_now(9)` une 2ème fois
- [ ] Vérifier que le nombre d'events n'a PAS doublé

## 5. Vérification visuelle sur /evenements

- [ ] Les events de Marc (vendredis) apparaissent dans la liste chronologique
- [ ] Les events de Peter apparaissent aux bonnes dates
- [ ] Cliquer sur un event → la modal affiche les bonnes infos (titre, lieu, prix, prof)
- [ ] Les badges Atelier/Stage sont corrects (vendredis = atelier, stages multi-jours = stage)

## 6. Edge cases

- [ ] Un event sans recurrence (normal) est créé correctement
- [ ] Un event avec recurrence mais `day_of_week` invalide → pass-through (1 event)
- [ ] Les events passés (avant aujourd'hui) ne sont PAS générés par RecurrenceExpander

---

**Commandes utiles :**

```bash
# Parser Marc Silvestre
bin/rails runner "EventUpdateJob.perform_now(7)"

# Parser Peter Wilberforce
bin/rails runner "EventUpdateJob.perform_now(9)"

# Compter events par prof
bin/rails runner "Event.group(:professor_id).count.each { |id, c| puts \"#{Professor.find(id).nom}: #{c}\" }"

# Voir les vendredis de Marc
bin/rails runner "Event.where(scraped_url_id: 7).where('titre LIKE ?', '%Vagues%').order(:date_debut).each { |e| puts \"#{e.date_debut.strftime('%A %d/%m/%Y')} #{e.titre}\" }"

# Vérifier pas de doublon
bin/rails runner "puts Event.group(:scraped_url_id, :date_debut, :titre).having('count(*) > 1').count.size.to_s + ' doublons'"
```

---

**Date :** 2026-04-08
**Validé par :** _______________
