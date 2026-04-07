# Guide DaisyUI — Stop & Dance

**Version :** DaisyUI 5.5.19 + Tailwind CSS v4
**Fichier de config unique :** `app/assets/tailwind/application.css`

---

## 1. Thème custom "stopanddance"

Tout le thème est défini dans `app/assets/tailwind/application.css` :

```css
@plugin "daisyui/theme" {
  name: "stopanddance";
  default: true;
  color-scheme: light;

  /* Couleurs principales */
  --color-primary: #C2623F;           /* Terracotta — boutons, liens, titres */
  --color-primary-content: #FFFFFF;   /* Texte sur primary */
  --color-secondary: #D4A017;         /* Moutarde — accents */
  --color-secondary-content: #FFFFFF;

  /* Fond et texte */
  --color-base-100: #F5E6D3;          /* Beige — fond principal */
  --color-base-200: #E8D4BB;          /* Beige foncé — fond secondaire */
  --color-base-300: #D4BFA3;          /* Beige encore plus foncé */
  --color-base-content: #1A1A1A;      /* Texte principal */

  /* Navbar / Footer */
  --color-neutral: #1A1A1A;           /* Fond sombre */
  --color-neutral-content: #F5E6D3;   /* Texte sur fond sombre */

  /* Couleurs utilitaires */
  --color-accent: #1A1A1A;
  --color-info: #3B82F6;
  --color-success: #22C55E;
  --color-warning: #D4A017;
  --color-error: #EF4444;

  /* Dimensions */
  --rounded-box: 0.75rem;             /* Arrondi des cards */
  --rounded-btn: 0.5rem;              /* Arrondi des boutons */
  --rounded-badge: 1rem;              /* Arrondi des badges */
}
```

### Modifier les couleurs

1. Ouvrir `app/assets/tailwind/application.css`
2. Changer la valeur hex voulue (ex: `--color-primary: #8B4513;`)
3. Rebuilder : `bin/rails tailwindcss:build`
4. Recharger la page

**Tout le site suit automatiquement** — pas besoin de toucher aux vues.

### Modifier les arrondis

```css
--rounded-box: 0;        /* Pas d'arrondi (carré) */
--rounded-box: 0.5rem;   /* Léger */
--rounded-box: 0.75rem;  /* Défaut actuel */
--rounded-box: 1rem;     /* Plus arrondi */
--rounded-box: 2rem;     /* Très arrondi */
```

---

## 2. Composants utilisés

### Boutons (`btn`)

```erb
<%= link_to "Texte", path, class: "btn btn-primary" %>
```

**Variantes de couleur :**
- `btn-primary` — terracotta
- `btn-secondary` — moutarde
- `btn-accent` — sombre
- `btn-neutral` — noir
- `btn-ghost` — transparent
- `btn-outline` — bordure seule
- `btn-outline btn-primary` — bordure terracotta

**Tailles :**
- `btn-xs` — très petit
- `btn-sm` — petit
- `btn-md` — moyen (défaut)
- `btn-lg` — grand

**Formes :**
- `btn-circle` — rond
- `btn-square` — carré
- `btn-wide` — large

### Cards (`card`)

```erb
<div class="card bg-base-100 shadow-sm">
  <div class="card-body">
    <h2 class="card-title">Titre</h2>
    <p>Contenu</p>
  </div>
</div>
```

**Card horizontale (event cards) :**
```erb
<div class="card card-side">
  <figure><img src="..." /></figure>
  <div class="card-body">...</div>
</div>
```

### Badges (`badge`)

```erb
<span class="badge badge-primary">Atelier</span>
<span class="badge badge-info">En ligne</span>
<span class="badge badge-outline">Présentiel</span>
<span class="badge badge-success">Gratuit</span>
```

**Tailles :** `badge-xs`, `badge-sm`, `badge-md`, `badge-lg`

### Formulaires

```erb
<%= f.text_field :q, class: "input input-bordered w-full" %>
<%= f.email_field :email, class: "input input-bordered w-full" %>
<%= f.date_field :date, class: "input input-bordered w-full" %>
<%= f.check_box :gratuit, class: "checkbox checkbox-primary checkbox-sm" %>
<%= f.select :model, options, {}, class: "select select-bordered w-full" %>
```

**Tailles :** `input-xs`, `input-sm`, `input-md`, `input-lg`

### Navbar

```erb
<nav class="navbar bg-neutral text-neutral-content">
  <div class="navbar-start">...</div>
  <div class="navbar-center">...</div>
  <div class="navbar-end">...</div>
</nav>
```

### Hero

```erb
<section class="hero min-h-screen bg-neutral text-neutral-content">
  <div class="hero-content text-center">
    <div class="max-w-3xl">
      <h1>Titre</h1>
      <p>Description</p>
    </div>
  </div>
</section>
```

### Footer

```erb
<footer class="footer bg-neutral text-neutral-content p-10">
  <nav>
    <h6 class="footer-title">Section</h6>
    <a class="link link-hover">Lien</a>
  </nav>
</footer>
```

### Alertes (flash messages)

```erb
<div role="alert" class="alert alert-success">
  <span>Message de succès</span>
</div>
<div role="alert" class="alert alert-error">
  <span>Message d'erreur</span>
</div>
```

### Stats

```erb
<div class="stats shadow">
  <div class="stat">
    <div class="stat-title">Label</div>
    <div class="stat-value text-primary">1234</div>
    <div class="stat-desc">Description</div>
  </div>
</div>
```

### Menu (navigation drawer)

```erb
<ul class="menu">
  <li><a>Item 1</a></li>
  <li><a>Item 2</a></li>
</ul>
```

### Avatar placeholder

```erb
<div class="avatar placeholder">
  <div class="bg-primary text-primary-content w-32 h-32 rounded-full">
    <span class="text-5xl">D</span>
  </div>
</div>
```

### Loading spinner

```erb
<span class="loading loading-spinner loading-md text-primary"></span>
```

### Divider

```erb
<div class="divider"></div>
```

### Join (input + bouton collés)

```erb
<div class="join w-full">
  <input type="text" class="input input-bordered join-item w-full">
  <button class="btn btn-primary join-item">Action</button>
</div>
```

---

## 3. Couleurs custom Tailwind (en plus de DaisyUI)

Les couleurs custom restent disponibles via `@theme` :

```css
@theme {
  --color-terracotta: #C2623F;
  --color-beige: #F5E6D3;
  --color-dark-bg: #1A1A1A;
  --color-moutarde: #D4A017;
}
```

Usage : `bg-terracotta`, `text-moutarde`, etc. Mais préférer les classes DaisyUI sémantiques (`btn-primary`, `bg-base-100`) pour la cohérence.

---

## 4. Workflow modification design

1. Modifier `app/assets/tailwind/application.css` (thème ou classes)
2. `bin/rails tailwindcss:build`
3. Recharger la page
4. Si ajout d'une nouvelle classe DaisyUI dans une vue → le build la détecte automatiquement

---

## 5. Référence rapide DaisyUI

**Documentation complète :** https://daisyui.com/components/

**Composants les plus utiles :**

| Composant | Classe | Usage |
|-----------|--------|-------|
| Bouton | `btn` | Actions, liens |
| Card | `card` | Conteneur avec titre/corps |
| Badge | `badge` | Labels, tags, statuts |
| Input | `input` | Champs texte |
| Checkbox | `checkbox` | Cases à cocher |
| Select | `select` | Menus déroulants |
| Navbar | `navbar` | Barre de navigation |
| Footer | `footer` | Pied de page |
| Hero | `hero` | Section d'accroche |
| Alert | `alert` | Messages flash |
| Stats | `stats` | Chiffres clés |
| Menu | `menu` | Navigation verticale |
| Modal | `modal` | Fenêtres modales |
| Divider | `divider` | Séparateur |
| Loading | `loading` | Indicateur de chargement |
| Avatar | `avatar` | Photo/initiales profil |
| Join | `join` | Grouper des éléments |
| Tooltip | `tooltip` | Info-bulle |
| Collapse | `collapse` | Accordéon |
| Tabs | `tabs` | Onglets |
| Table | `table` | Tableau stylé |

---

**Dernière mise à jour :** 2026-04-07
