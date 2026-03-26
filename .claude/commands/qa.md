---
description: Lance l'audit QA complet (8 sections) - Trouve et corrige tous les bugs
---

Tu es le QA Engineer automatisé. Lance l'audit complet en 8 sections.

**Processus obligatoire :**

1. Créer la todo list avec les 8 sections
2. Exécuter chaque section dans l'ordre
3. Pour chaque bug trouvé : corriger immédiatement, tester, commit + push
4. Générer rapport final markdown dans `tmp/QA_AUDIT_[DATE].md`

---

## Section 1 : TESTS UNITAIRES

Lancer `rails test` — vérifier zéro failure, zéro error.

Si échecs :
- Lire les messages d'erreur
- Corriger le code
- Relancer `rails test` jusqu'à 100% vert
- Commit + push les corrections

---

## Section 2 : TESTS SYSTÈME

Lancer `rails test:system` — Capybara + Playwright headless.

Si échecs :
- Lire les messages d'erreur + screenshots dans tmp/screenshots/
- Corriger les tests ou le code
- Relancer jusqu'à 100% vert
- Commit + push les corrections

---

## Section 3 : ROUTES

1. Lancer le serveur Rails (si pas déjà running)
2. Lister TOUTES les routes : `rails routes`
3. Curl chaque route publique → vérifier status 200
4. Curl chaque route admin avec HTTP Basic Auth → vérifier status 200
5. Curl routes admin SANS auth → vérifier status 401

Si erreurs (404, 500, etc.) :
- Identifier la cause (controller, route, vue manquante)
- Corriger
- Re-tester
- Commit + push

---

## Section 4 : LIENS

1. Grep tous les `link_to` dans `app/views/**/*.html.erb`
2. Extraire tous les route helpers (ex: `evenements_path`, `professor_path(@prof)`)
3. Vérifier que chaque helper existe dans `rails routes`
4. Signaler les routes mortes (helper appelé mais route inexistante)

Si routes mortes :
- Soit ajouter la route manquante
- Soit supprimer le lien
- Commit + push

---

## Section 5 : MODÈLES

1. Lister tous les modèles dans `app/models/`
2. Pour chaque modèle :
   - Vérifier associations `belongs_to` / `has_many` cohérentes
   - Vérifier que les foreign keys existent dans les migrations
3. Lancer script console Rails :
   - Vérifier aucune donnée orpheline (Event sans Professor si belongs_to required, etc.)
   - Tester les associations en console

Si incohérences :
- Corriger les associations
- Ajouter validations manquantes
- Nettoyer données orphelines
- Commit + push

---

## Section 6 : VUES

1. Grep tous les `render partial:` dans `app/views/`
2. Pour chaque partial :
   - Vérifier que le fichier `_nom.html.erb` existe
   - Vérifier que les variables locales passées (ex: `locals: { event: @event }`) sont utilisées
   - Vérifier pas de crash sur données nil (ex: `event.professor.nom` sans safe navigation)

Si erreurs :
- Créer partials manquants
- Corriger variables
- Ajouter safe navigation (`&.`)
- Commit + push

---

## Section 7 : CONVENTIONS PROJET

Lire `CLAUDE.md` du projet → section conventions.

Pour chaque convention, grep le code :
- **Pagy** : grep `.page(` → doit être 0 résultat (utiliser Pagy, pas Kaminari)
- **Time.current** : grep `Date.current` → doit être 0 résultat
- **increment_counter** : grep `.increment!(` → doit être 0 résultat
- **Timezone UTC** : vérifier `config/application.rb` contient `config.active_record.default_timezone = :utc`

Si violations :
- Corriger le code
- Commit + push

---

## Section 8 : TESTS SYSTÈME UX

Vérifier que les tests système couvrent :
- Filtres (checkboxes, date input)
- Modals/overlays (ouvrent et ferment)
- Formulaires (newsletter, admin)
- Infinite scroll (si applicable)
- Navigation mobile (si applicable)

Si tests manquants :
- Les créer dans `test/system/`
- Lancer `rails test:system`
- Commit + push

---

## RAPPORT FINAL

Générer `tmp/QA_AUDIT_[DATE].md` avec :
- Date et heure de l'audit
- Résumé exécutif (tous tests passent ✅ ou bugs trouvés)
- Liste de tous les bugs trouvés et corrigés
- Commits effectués
- Statistiques finales (tests, assertions, failures)
- Conclusion : Application production-ready ou non

Commit le rapport (pas le push).

---

**IMPORTANT :**
- Ne PAS sauter de section
- Corriger TOUS les bugs avant de passer à la section suivante
- Commit + push après chaque correction
- Générer le rapport final obligatoirement
