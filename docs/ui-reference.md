# UI Reference — Stop & Dance

## Design System

### Palette
- **Primary** : Terracotta / orangé (#C2623F ou similaire)
- **Secondary** : Beige / crème clair
- **Background** : Fond sombre (presque noir)
- **Text** : Blanc sur fond sombre / sombre sur beige
- **Accents** : Tons terracotta pour boutons CTA, headers sidebar

### Typographie
- Titres principaux : Police script/italique élégante (ex: "Stop & Dance")
- Corps de texte : Sans-serif lisible
- Labels/tags : Petite taille, fond coloré arrondi

### Tags / Pills
- **Atelier** : Fond terracotta
- **Stage** : Fond terracotta clair
- **Gratuit** : Fond vert doux
- **En ligne** : Fond bleu/teal
- **En présentiel** : Fond neutre

---

## Pages & Composants

### 1. Homepage — Hero

**Desktop & Mobile**
- Photo pleine largeur de danseurs (fond sombre, noir & blanc ou sépia)
- Logo "Stop & Dance" en grand — typographie script blanche
- Texte de présentation en italic blanc (paragraphe court)
- 6 boutons CTA arrondis en 2 rangées :
  - Rangée 1 : AGENDA (terracotta) · PUBLIES TES ATELIERS (terracotta) · ACTUALITÉS (terracotta)
  - Rangée 2 : QUI EST DUY (teal/vert) · ME CONTACTER (terracotta foncé) · DONATIONS (beige/kaki)

**Navigation**
- Logo petit en haut à gauche
- 3 icônes navigation en haut à droite (hamburger menu, calendrier, newsletter)
- Menu déroulant : Accueil, Agenda, S'inscrire à la newsletter, liens, L'espace des proposants

---

### 2. Liste Événements

**Desktop (sidebar permanente)**
- Colonne principale (gauche ~70%) : liste chronologique
- Sidebar droite (~30%) : Recherche + Filtres + Newsletter

**Mobile**
- Liste pleine largeur
- Bouton "Filtrez l'agenda" en haut → panel dépliable
- Titre "Liste des événements" en terracotta italic

**Séparateurs de dates**
- Format : "Samedi 18/11/2023" en italic gris/sombre
- Ligne de séparation fine

**Carte Événement**
```
[Photo 80x80]  10h15  [Tag Atelier] [Tag Gratuit]
               Titre de l'atelier
               Animé par : Prénom Nom
               📍 Ville  Prix : 0€
```
- Photo carrée à gauche
- Heure en terracotta bold
- Tags pills colorés
- Titre en bold
- "Animé par" en gris
- Icône pin 📍 + ville + prix

---

### 3. Fiche Événement (Modal)

**Structure mobile (pleine largeur)**
- Croix fermeture en haut à droite
- Tags en haut (Atelier · Gratuit · En présentiel)
- Carrousel photos (flèche navigation droite visible)
- Titre en italic
- Bloc infos structuré :
  ```
  Animé par : [Lien nom prof en terracotta]
  Début : JJ/MM/AAAA HH:mm
  Fin : JJ/MM/AAAA HH:mm
  Durée : Xh
  Où : [Lien nom lieu en terracotta]
        [Adresse complète en terracotta]
  Prix normal : XX€
  Prix réduit : XX€
  > www.siteduprof.fr  [lien terracotta]
  > email@prof.fr      [lien terracotta]
  ```
- Section DESCRIPTION en terracotta bold
- Texte description scrollable

---

### 4. Sidebar Filtres (Desktop) / Panel Filtres (Mobile)

**Header**
- "Filtrez l'agenda" en italic sur fond terracotta
- Croix fermeture (mobile uniquement)

**Filtres checkboxes (2 colonnes)**
```
EN PRÉSENTIEL ☑    STAGE ☑
EN LIGNE      ☑    GRATUIT ☑
ATELIER       ☑
```

**Filtre date**
```
À PARTIR DU  [JJ/MM/AAAA]
```

**Filtre géographique**
```
LIEU      [Adresse, ville...]
DISTANCE  [km]
```

**Bouton**
- APPLIQUER : bouton terracotta pleine largeur

---

### 5. Recherche

- Bloc terracotta foncé
- "Recherchez" en italic
- Champ texte avec icône loupe
- Placeholder : "Saisir votre recherche directement"

---

### 6. Newsletter (Sidebar)

- Bloc terracotta
- "S'inscrire à la newsletter" en italic
- Champ email
- Bouton SOUSCRIRE terracotta

---

## Comportements UI

### Mobile-first
- Référence : iPhone 12 Pro (390 × 844px)
- Filtres masqués par défaut → bouton "Filtrez l'agenda" pour déplier
- Panel filtres overlay pleine largeur

### Desktop
- Sidebar filtres visible en permanence à droite
- Largeur référence : 1728px (MacBook Pro 16")

### Mode sombre/clair
- Toggle disponible
- Préférence sauvegardée localement

### PWA
- Installable sur écran d'accueil mobile
- Network-first (pas de cache offline)
- Notification nouvelle version disponible

---

## Notes pour l'implémentation Tailwind

- Utiliser `dark:` variants pour mode sombre
- Couleur terracotta : définir comme custom color dans `tailwind.config.js`
- Cards événements : `flex`, gap, padding cohérent
- Tags pills : `rounded-full`, `px-3`, `py-1`, `text-sm`
- Sidebar : `sticky top-0` sur desktop, `hidden` sur mobile
- Panel filtres mobile : `fixed inset-0` ou `slide-in` animation
