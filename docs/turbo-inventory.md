# Inventaire Turbo

Mis à jour : 2026-04-20

État complet de tous les turbo-frames, turbo_stream et attributs `data-turbo-*` du projet, pour savoir **ce qui se rafraîchit et par quel canal** quand on touche à une vue.

---

## 1. Frames publics

### `/evenements` (index)

| Frame | Localisation | Rôle |
|---|---|---|
| `filter-pill` | `app/views/events/index.html.erb:3` | Pill "Filtrez l'agenda" / "Agenda filtré" sticky mobile (partial `_filter_pill`) |
| `events-list` | `app/views/events/index.html.erb:21` | Liste des events + h1 "Agenda complet : X et Y" + trigger infinite scroll |
| `page-N` | généré dynamiquement dans `events-list` | Lazy-load infinite scroll (src `?page=N&format=turbo_stream`) |
| `event_modal` | `app/views/events/index.html.erb:50` (placeholder) + `show.html.erb:1` (contenu) | Conteneur de la modale event, cible des clics sur `_event_card` |

**Form filtres** (`_filters.html.erb`) :
- **Pas de** `data-turbo-frame` (car on met à jour plusieurs frames)
- `format: :turbo_stream` pour que le controller renvoie le turbo_stream
- `data-turbo-action: advance` pour MAJ l'URL dans l'historique

**Réponse `index.turbo_stream.erb`** (events) :
- Si `params[:page].to_i > 1` → `turbo_stream.replace "page-N"` (infinite scroll)
- Sinon → `turbo_stream.replace "events-list"` + `turbo_stream.replace "filter-pill"` (filter submit)

### `/evenements/:id` (show modal)

- Le fichier `show.html.erb` est entièrement wrappé dans `turbo_frame_tag "event_modal"` → quand un lien `_event_card` (`data-turbo-frame="event_modal"`) est cliqué, Turbo va chercher ce frame dans la réponse et remplace le frame vide présent sur `index.html.erb`.
- Bouton × = `<a href="/evenements" data-turbo-frame="_top">` → recharge la page complète (navigation hors frame), vide donc la modal.
- Clic overlay = `data-action="click->modal#close"` sur le div `modal` → `modal_controller.js` retire l'élément du DOM + `history.replaceState` vers `/evenements` sans navigation.

### `/proposants` (index)

| Frame | Localisation | Rôle |
|---|---|---|
| `proposants-list` | `app/views/proposants/index.html.erb:26` | Liste profs + trigger infinite scroll |
| `page-N` | dans `proposants-list` | Lazy-load infinite scroll |
| `proposant_modal` | `app/views/proposants/index.html.erb:53` (placeholder) + `show.html.erb:1` (contenu) | Conteneur modale prof |

**Form recherche** :
- `data-turbo-frame: "proposants-list"` (un seul frame à MAJ)
- `data-turbo-action: "advance"`
- `data-controller: "auto-submit"` avec debounce 300ms sur `input`

**Réponse `index.turbo_stream.erb`** (proposants) :
- `turbo_stream.replace "page-N"` systématiquement (cible unique, pas besoin de multi-frames car pas de pill)

### `/proposants/:id` (show modal)

- Pattern identique à `/evenements/:id` : wrapping `turbo_frame_tag "proposant_modal"`, bouton × = `data-turbo-frame="_top"`, clic overlay via `modal_controller`.
- Liens externes dans la modal : `data-turbo: false` (navigation externe, bypass Turbo).
- Boutons "Profil complet" / "Statistiques" : `data-turbo-frame: "_top"` pour sortir de la modale et recharger la page.

---

## 2. Frames admin (infinite scroll tables)

Pattern unifié pour toutes les tables admin :

| Page | Frame principal | Pagination |
|---|---|---|
| `/admin/events` | `admin-events-list` (tbody `admin-events-tbody`) | `admin-events-page-N` |
| `/admin/professors` | `admin-professors-list` (tbody `admin-professors-tbody`) | `admin-professors-page-N` |
| `/admin/site_crawls` | `admin-site-crawls-list` | `admin-site-crawls-page-N` |
| `/admin/notifications` | `admin-notifications-list` | `admin-notifications-page-N` |
| `/admin/jobs` | 2 frames : `admin-jobs-ready-list` + `admin-jobs-failed-list` | `admin-jobs-ready-page-N` + `admin-jobs-failed-page-N` |

**Pattern générique** :
- `turbo_stream.append "admin-{resource}-tbody"` pour ajouter les lignes
- `turbo_stream.replace "admin-{resource}-page-N"` pour remplacer le trigger lazy
- Actions (Éditer, Supprimer, Relancer…) : `data-turbo-frame: "_top"` → sortent du frame pour navigation complète

---

## 3. Points d'entrée Turbo dans le layout

Fichier | Contenu
---|---
`app/views/layouts/application.html.erb:23` | `stylesheet_link_tag :app, "data-turbo-track": "reload"` (recharge auto quand CSS change)
`app/views/layouts/admin.html.erb:9` | idem admin

---

## 4. Modal controller (partagé)

`app/javascript/controllers/modal_controller.js` :
- `close()` : retire `this.element` du DOM + `history.replaceState` vers `/evenements` ou `/proposants` (liste configurable).
- `stopPropagation(event)` : empêche les clics sur le panel interne de remonter au overlay.

**Utilisé par** : `events/show.html.erb` et `proposants/show.html.erb` (même pattern).

---

## 5. Règles d'or apprises à la dure

### 5.1 Form `data-turbo-frame="X"` = cible UNIQUE
Si le form a `data-turbo-frame="X"`, Turbo **ignore les turbo_stream pour tout autre frame** dans la réponse. Seul le frame X est mis à jour.
- **Symptôme typique** : tu mets à jour le pill dans un `turbo_stream.replace "filter-pill"`, mais le pill ne bouge pas car le form ciblait uniquement `events-list`.
- **Solution** : retirer `data-turbo-frame` du form et ajouter `format: :turbo_stream` pour que la réponse soit interprétée en multi-frame.

### 5.2 Lien `<a>` dans `<a>` = layout cassé
HTML5 interdit les `<a>` imbriqués. Le parseur retire l'enfant `<a>` du parent, ce qui casse les layouts `.card-side`.
- **Symptôme** : une `card-body` disparaît du DOM rendu alors qu'elle est dans le HTML source.
- **Solution** : utiliser `<span>` pour les éléments cliquables visuels dans une card `<a>`, et mettre les vrais `<a>` dans la modal.

### 5.3 `modal_controller` doit exister
Si une vue utilise `data-controller="modal"` mais que `app/javascript/controllers/modal_controller.js` n'existe pas, le clic overlay ne fait rien (pas d'erreur JS, juste silence).

### 5.4 Turbo Drive + sticky top-0 = navbar dispo uniquement au repos
La navbar mobile est `sticky top-0` mais son parent `<div class="lg:hidden">` ne fait que la hauteur de la navbar → au scroll, la navbar sort du viewport. C'est le comportement voulu (gain d'espace mobile), donc le pill filtre est collé `top-0` pour rester repère visuel seul.

### 5.5 Infinite scroll + form submit : 2 branches dans `index.turbo_stream.erb`
Quand une page a les deux (scroll infini + filtres), le `turbo_stream.erb` doit brancher sur `params[:page]` :
- `page > 1` → replace trigger `page-N` uniquement
- sinon → replace frame principal complet + frames annexes (pill, compteurs…)

### 5.6 `auto_submit_controller` : `change` ou `input` ?
- `change` : déclenché sur checkboxes, blur text, selects. Instantané.
- `input` : déclenché sur chaque frappe dans un text field. **Débouncé à 300ms** par défaut dans notre `auto_submit_controller.js` pour éviter une requête par caractère.
- Choix : `change` pour les formulaires classiques, `input` pour recherche temps réel.
