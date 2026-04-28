# Identité Visuelle Bydou — Système de Design v2

> **Document de référence brand pour toutes les plateformes.**
> **Date** : avril 2026 · **Status** : validé pour implémentation

---

## 1. Vue d'ensemble

Identité visuelle unifiée pour Stop & Dance, Aujourduy.fr, supports DCAV, chaîne YouTube, présence Facebook, et tous futurs supports.

### Distinctive Brand Assets

Trois éléments de reconnaissance instantanée (modèle Byron Sharp, *How Brands Grow*) :

1. **Terracotta `#BF462E`** — couleur primary identitaire
2. **Fraunces avec axe WONK** — typographie display variable, paradoxe Nasreddine intégré
3. **Bleu chàm `#1F3158`** — contrepoint culturel, indigo traditionnel vietnamien

Tout le reste du système est en service de ces 3 assets.

### Polarité assumée

La palette globale (terre + sage + crème + chàm) communique une posture **contemplative organique avec contrepoint de précision**. Cohérent avec le positionnement "pédagogue du vivant". Le tranchant Nasreddine et l'énergie Promoteur passent par la typographie (Fraunces wonk), la voix copywriting, et le Corail vif en accent CTA — pas par la palette seule.

---

## 2. Palette — 9 couleurs

### Couleurs principales (60-30-10)

| Nom | Hex | RGB | Rôle | Usage |
|-----|-----|-----|------|-------|
| **Terracotta** | `#BF462E` | rgb(191, 70, 46) | Primary | Identité forte, boutons d'action principale, titres porteurs, identifiants section |
| **Eucalyptus** | `#6C9D9A` | rgb(108, 157, 154) | Secondary | Actions informatives, identité froide, contraste structurel |
| **Corail vif** | `#F2815A` | rgb(242, 129, 90) | Accent (10%) | CTA exclusivement. Jamais en aplat large. |

### Couleurs de soutien

| Nom | Hex | RGB | Rôle | Usage |
|-----|-----|-----|------|-------|
| **Argile rose** | `#BB8777` | rgb(187, 135, 119) | Soutien chaud | Hover states, micro-éléments, transitions. Jamais en aplat large. |
| **Sable** | `#B29D7E` | rgb(178, 157, 126) | Neutre chaud | Sections calmes, zones non-pressantes, fonds doux |
| **Bleu chàm** | `#1F3158` | rgb(31, 49, 88) | Contrepoint précision | Pull-quotes intellectuels, framework Spira5, sections "rigueur", liens de profondeur |

### Neutres système

| Nom | Hex | RGB | Rôle | Usage |
|-----|-----|-----|------|-------|
| **Crème lumière** | `#F8F3EA` | rgb(248, 243, 234) | base-100 | Fond principal partout. Anti-blanc clinique. |
| **Sable ombré** | `#E8DCCA` | rgb(232, 220, 202) | base-200 | Fond alterné, cards, sections secondaires |
| **Brun profond** | `#2D231C` | rgb(45, 35, 28) | base-content | Texte principal, contraste maximum |

### Hiérarchie texte (3 opacités du Brun profond)

| Niveau | Valeur | Hex équivalent | Usage |
|--------|--------|----------------|-------|
| **Principal** | `rgba(45, 35, 28, 1)` | `#2D231C` | Body paragraphes, titres |
| **Secondaire** | `rgba(45, 35, 28, 0.7)` | `#6E635B` | Métadonnées, captions, dates, attributions |
| **Tertiaire** | `rgba(45, 35, 28, 0.45)` | `#A6968B` | Hints, placeholders, disabled, légendes faibles |

### Règle 60-30-10

- **60%** : Crème lumière `#F8F3EA` (background dominant)
- **30%** : Eucalyptus + Sable + Sable ombré (zones structurelles, contraste)
- **10%** : Terracotta + Corail vif (accents identitaires + CTA)

Argile rose, Bleu chàm, Brun profond sont **hors quota 60-30-10** : ils servent des fonctions ponctuelles précises.

---

## 3. Typographie

### Polices

- **Fraunces** (display, headlines) — serif variable contemporain par Undercase Type. Axes : `wght` 100-900, `opsz` 9-144, `SOFT` 0-100, `WONK` 0-1.
- **Inter** (body, UI, métadonnées, chiffres) — sans-serif neutre haute lisibilité par Rasmus Andersson.

### Échelle typographique (web)

| Niveau | Police | Taille | Weight | Line-height | Letter-spacing |
|--------|--------|--------|--------|-------------|----------------|
| Display XL | Fraunces | 64px | 900 | 1.05 | -1px |
| H1 | Fraunces | 48px | 700 | 1.1 | -0.5px |
| H2 | Fraunces | 32px | 700 | 1.15 | -0.5px |
| H3 | Fraunces | 24px | 700 | 1.2 | -0.25px |
| Body large | Inter | 17px | 400 | 1.7 | 0 |
| Body | Inter | 15px | 400 | 1.7 | 0 |
| Caption | Inter | 13px | 400 | 1.6 | 0 |
| Small | Inter | 12px | 400 | 1.5 | 0.2px |
| Eyebrow / Label | Inter | 11px | 500 | 1.5 | 1px (uppercase) |

### Axes Fraunces — quand utiliser quoi

| Registre | Réglage | Usage |
|----------|---------|-------|
| **Dansant** | `font-variation-settings: 'SOFT' 50, 'WONK' 1` | Stop & Dance, communauté, posts FB chaleureux, bannière YouTube hero |
| **Profond** | `font-variation-settings: 'SOFT' 100, 'WONK' 0` | DCAV, Spira5, Baret, citations philosophiques |
| **Impact** | `font-weight: 900, 'SOFT' 50` | YouTube thumbnails, bannières impact, posters |
| **Italique** | Italic 400 | Pull-quotes, attributions, accents éditoriaux, taglines |

---

## 4. Implémentation Tailwind + DaisyUI

### tailwind.config.js complet

```js
module.exports = {
  content: ["./app/**/*.{html,erb,js,jsx}"],
  theme: {
    extend: {
      fontFamily: {
        display: ['Fraunces', 'Georgia', 'serif'],
        sans: ['Inter', 'Arial', 'sans-serif'],
      },
      colors: {
        terracotta: '#BF462E',
        eucalyptus: '#6C9D9A',
        corail: '#F2815A',
        argile: '#BB8777',
        sable: '#B29D7E',
        cham: '#1F3158',
        creme: '#F8F3EA',
        'sable-ombre': '#E8DCCA',
        brun: '#2D231C',
      },
    },
  },
  plugins: [require('daisyui')],
  daisyui: {
    themes: [
      {
        bydou: {
          "primary": "#BF462E",
          "primary-content": "#F8F3EA",
          "secondary": "#6C9D9A",
          "secondary-content": "#F8F3EA",
          "accent": "#F2815A",
          "accent-content": "#2D231C",
          "neutral": "#2D231C",
          "neutral-content": "#F8F3EA",
          "base-100": "#F8F3EA",
          "base-200": "#E8DCCA",
          "base-300": "#B29D7E",
          "base-content": "#2D231C",
          "info": "#1F3158",
          "info-content": "#F8F3EA",
          "success": "#6C9D9A",
          "success-content": "#F8F3EA",
          "warning": "#BB8777",
          "warning-content": "#2D231C",
          "error": "#8B2A1A",
          "error-content": "#F8F3EA",
        },
      },
    ],
  },
}
```

### Activation du thème

Dans `app/views/layouts/application.html.erb` :
```erb
<html data-theme="bydou">
```

### Chargement des polices

**Option A — Google Fonts (CDN, plus simple)**

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght,SOFT,WONK@0,9..144,400..900,0..100,0..1;1,9..144,400..900,0..100,0..1&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
```

**Option B — Self-hosted via @fontsource (recommandé pour Rails)**

```bash
yarn add @fontsource-variable/fraunces @fontsource/inter
```

```js
import "@fontsource-variable/fraunces"
import "@fontsource-variable/fraunces/wght-italic.css"
import "@fontsource/inter/400.css"
import "@fontsource/inter/500.css"
import "@fontsource/inter/600.css"
import "@fontsource/inter/700.css"
```

---

## 5. CSS variables (pour usages hors Tailwind)

```css
:root {
  /* Couleurs */
  --color-terracotta: #BF462E;
  --color-eucalyptus: #6C9D9A;
  --color-corail: #F2815A;
  --color-argile: #BB8777;
  --color-sable: #B29D7E;
  --color-cham: #1F3158;
  --color-creme: #F8F3EA;
  --color-sable-ombre: #E8DCCA;
  --color-brun: #2D231C;

  /* Hiérarchie texte */
  --text-primary: rgba(45, 35, 28, 1);
  --text-secondary: rgba(45, 35, 28, 0.7);
  --text-tertiary: rgba(45, 35, 28, 0.45);

  /* Polices */
  --font-display: 'Fraunces', Georgia, serif;
  --font-sans: 'Inter', Arial, sans-serif;
}
```

---

## 6. Application par plateforme

### 6.1 Site Stop & Dance / Aujourduy.fr

- Fond global : Crème lumière `#F8F3EA`
- Headers : Fraunces 700 en Terracotta ou Brun profond
- CTA primaires : Terracotta avec texte Crème
- CTA secondaires : Eucalyptus
- Citations Baret / Spira5 : Fraunces Italic en Bleu chàm avec `border-left: 3px solid #1F3158`
- Body : Inter 15-17px, Brun profond
- Cards événements : fond Sable ombré, bordures fines Brun à 15% opacité

### 6.2 YouTube — Bannière channel art

| Paramètre | Valeur |
|-----------|--------|
| Dimensions complètes | 2560 × 1440 px |
| Safe zone tous appareils (toute info critique) | 1546 × 423 px centré |
| Fond centre | Crème lumière `#F8F3EA` |
| Fond extensions latérales (optionnel) | Sable ombré `#E8DCCA` |
| Eyebrow | Inter 500 caps, letter-spacing 2px, 24-32px, Brun à 55% opacité |
| Titre principal | Fraunces Bold 700, `'SOFT' 50, 'WONK' 1`, 80-120px selon longueur (4-8 mots max), Terracotta `#BF462E` |
| Trait signature sous titre | Bleu chàm `#1F3158`, 2px d'épaisseur, 32px de long |
| Tagline | Fraunces Italic 400, 24-32px, Brun profond à 70% opacité |
| Signature URL | Inter 12px en bas à droite, Brun à 40% |
| Logo Aujourduy calligraphique | Optionnel, en haut à droite ou centré au-dessus du titre |

**Règle critique** : aucune information critique (titre, tagline, URL) en dehors de la safe zone 1546 × 423. Les extensions latérales sont décoratives uniquement.

### 6.3 YouTube — Miniatures (thumbnails)

| Paramètre | Valeur |
|-----------|--------|
| Dimensions | 1280 × 720 px |
| Police | Fraunces Black 900 uniquement (lisibilité petit format) |
| Taille texte hero | 140-180px, 4-6 mots max |
| Couleur option A | Crème `#F8F3EA` sur fond Brun profond `#2D231C` |
| Couleur option B | Brun profond `#2D231C` sur fond Crème `#F8F3EA` |
| Accent | Terracotta sur 1 mot ou élément graphique, ≤ 10% de la surface |
| Visage | Portrait à droite, regard caméra, expression alignée au sujet |

**Anti-patterns thumbnails** : pas de flèche rouge, pas de bouche grand ouverte stupéfaite, pas de fond explosé multicolore, pas de halo coloré, pas de texte en cercle. Ce n'est pas l'univers Bydou.

### 6.4 Facebook — Cover (page perso ou page Aujourduy)

| Paramètre | Valeur |
|-----------|--------|
| Dimensions | 1640 × 856 px |
| Safe zone mobile | 820 × 312 px centré |
| Police titre | Fraunces Bold 700, ~96px |
| Fond option A | Crème lumière `#F8F3EA` |
| Fond option B | Brun profond `#2D231C` (pour photo associée) |
| Photo (optionnelle) | Portrait noir/blanc subtil ou scène danse, désaturée à 30-40% en arrière-plan |
| Tagline | Inter 500, ~24px, Brun secondaire (à 70% opacité) |

### 6.5 Facebook — Posts carrés et stories

| Paramètre | Carré | Story |
|-----------|-------|-------|
| Dimensions | 1080 × 1080 px | 1080 × 1920 px |
| Marge interne minimum | 80px | 90px |
| Police titre | Fraunces 700-900 selon impact | Fraunces 900 |
| Hiérarchie texte | Eyebrow Inter caps + titre Fraunces + body Inter 400 | idem |
| Palette par visuel | 1 couleur dominante max + 1 accent | idem |
| CTA | Corail vif `#F2815A` rectangle bouton, texte Crème, Inter 500, padding 16px | idem |

**Règle critique** : jamais 4 couleurs sur un même visuel social. Discipline 60-30-10 stricte.

### 6.6 Supports DCAV (sales page, workbooks, présentations)

- Sales page : registre profond — Fraunces SOFT 100 + Bleu chàm pull-quotes + Brun profond body
- Documents print : Crème ou Sable ombré en fond, Brun en texte
- Workbooks : hiérarchie 3 opacités stricte
- Présentations : Fraunces Black 900 titres, Inter body, Bleu chàm pour frameworks Spira5

---

## 7. Assets brand à fournir séparément

Pour utilisation avec un outil de génération visuelle (Claude Design, Canva, Figma) ou pour intégration dans un codebase, fournir en complément du présent document :

- **Logo Aujourduy calligraphique** : SVG ou PNG transparent haute résolution. Mark distinctif à conserver intact dans tous les visuels brand. Ne jamais remplacer par "Aujourduy" en Fraunces — la calligraphie EST l'asset.
- **Photos authentiques** : portrait Bydou (regard caméra, expression naturelle), scènes de danse libre, lieux d'événements. Jamais de photo stock générique.
- **Captures du site Aujourduy.fr** : 2-3 screenshots des pages clés pour référence visuelle de l'esthétique existante.
- **Références visuelles d'inspiration** (mood board) : Aesop, Defector, Are.na, textile chàm vietnamien (H'mong/Tày). Ces références ancrent le ton visuel sans en faire des modèles à copier.

---

## 8. Anti-patterns — À ne JAMAIS faire

- Utiliser **noir pur `#000`** en texte → toujours Brun profond `#2D231C`
- Utiliser **blanc pur `#FFFFFF`** en fond → toujours Crème lumière `#F8F3EA`
- Mettre **Corail vif en aplat large** → l'accent perd sa fonction (10% strict)
- Mettre **Bleu chàm en CTA** → Bleu chàm = profondeur intellectuelle, pas appel à action
- Mettre **Eucalyptus en texte body** → contraste insuffisant (2.7:1), usage graphique seulement
- Mélanger **Eucalyptus et Argile rose en proportions égales** → tension chromatique sans signal
- Utiliser **Fraunces WONK partout** → la surprise s'use, garder pour moments distinctifs
- Mélanger **Fraunces + une autre police serif** → toujours Fraunces (display) + Inter (sans), point.
- Bolds en weight 600 ou 700 partout → 500 par défaut, 700 réservé aux titres Fraunces
- Utiliser une **photo stock générique** → photo authentique de danse / portrait / lieu uniquement
- Remplacer le **logo Aujourduy calligraphique par du texte Fraunces** → la calligraphie est un asset distinctif irremplaçable
- Mettre **plus de 3 couleurs principales sur un même visuel** social → 1 dominante + 1 accent maximum

---

## 9. Tests qualité

### Contraste WCAG (validation accessibilité)

| Combinaison | Ratio | Niveau |
|-------------|-------|--------|
| Brun profond sur Crème lumière | 14.4:1 | AAA |
| Crème lumière sur Brun profond | 14.4:1 | AAA |
| Bleu chàm sur Crème lumière | 11.3:1 | AAA |
| Crème lumière sur Bleu chàm | 11.3:1 | AAA |
| Terracotta sur Crème lumière | 4.7:1 | AA (texte ≥ 18px ou ≥ 14px gras) |
| Crème lumière sur Terracotta | 4.7:1 | AA (texte ≥ 18px ou ≥ 14px gras) |
| Eucalyptus sur Crème lumière | 2.7:1 | ❌ Échec — graphique uniquement |
| Terracotta sur Brun profond | 3.0:1 | ❌ Échec — non utilisable |

**Règles de contraste à respecter** :
- Texte body sur Crème : utiliser Brun profond uniquement
- Eucalyptus : couleur d'élément graphique (icônes, fonds, bordures), jamais texte sur Crème
- Terracotta en texte : taille large uniquement (≥ 18px), sur Crème
- Bleu chàm : excellente lisibilité partout sur Crème, idéal pour pull-quotes lisibles

### Test "0.3 seconde" (Sharp)

À chaque nouveau visuel, demander : *"En 0.3 seconde, ce visuel est-il reconnaissable comme Bydou ?"*
- Si Terracotta dominant + Fraunces visible → OUI
- Sinon → revoir

### Test Byron Katie sur formulations

Avant publication d'un visuel important : *"Est-ce que cette formulation, présentée ainsi, est vraie ?"*
Si non → reformuler. Si oui → publier.

---

## 10. Évolutions futures

Cette palette est conçue pour absorber sans rupture les futurs produits :

- **DCAV** : palette identique avec dominante Bleu chàm + Brun profond pour gravité philosophique
- **Spira5** : palette identique avec Bleu chàm dominant + Eucalyptus pour précision modélisation
- **Stop & Dance** : palette identique avec Terracotta + Corail dominants pour énergie communautaire
- **Personal brand Bydou** : palette complète, équilibrée

Si un futur produit demande une palette distincte (ex: marque sœur), maintenir au minimum **Fraunces** comme constante typographique pour bridge identitaire.

---

## 11. Rationnel des décisions

**Terracotta primary** — chaleur, ancrage, terre, intensité. Aligné avec "Du chaos au vivant" et danse incarnée. Distinctif sur le marché coaching/wellness français saturé (la majorité utilise Playfair + sage générique).

**Fraunces** — variable serif contemporain, axes SOFT/WONK introduisent surprise typographique = paradoxe Nasreddine codé dans la lettre. Permet 3 registres dans une seule famille (dansant, profond, impact). Pair utilisé par publications indépendantes pensantes (Defector, Are.na).

**Bleu chàm** — résonance vietnamienne (chàm = indigo traditionnel des textiles H'mong/Tày), contrepoint chaud/froid avec Terracotta (combo structurellement la plus forte en branding), précision mathématique/intellectuelle, distinctivité immédiate sur un marché saturé de palettes terre+sage.

**Crème lumière + Brun profond** — refus du noir/blanc clinique, posture "vivant" même dans les contrastes. Contraste 14.4:1 (zone optimale lecture longue, anti-fatigue par rapport au noir pur sur blanc à 21:1).

**Hiérarchie 3 opacités** — système éprouvé (Aesop, Linear, Stripe). Couvre 95% des besoins texte sans introduire de couleurs supplémentaires.

**Inter en body** — neutralité haute qualité, contemporary tech-aware, pair avec Fraunces sans tension visuelle (Fraunces porte la personnalité, Inter porte la fonction).

---

## 12. Checklist d'intégration Claude Code

À cocher lors de l'implémentation sur Stop & Dance :

- [ ] Ajouter Fraunces et Inter via `@fontsource` (Option B recommandée)
- [ ] Mettre à jour `tailwind.config.js` avec le bloc complet (section 4)
- [ ] Activer le thème `data-theme="bydou"` dans `application.html.erb`
- [ ] Créer `app/assets/stylesheets/_brand.css` avec les CSS variables (section 5)
- [ ] Vérifier que les classes DaisyUI existantes (`btn-primary`, `btn-accent`, etc.) reflètent la nouvelle palette
- [ ] Tester le contraste sur les pages clés (homepage, page événement, formulaire de recherche)
- [ ] Mettre à jour les composants custom qui utilisaient des couleurs hardcodées
- [ ] Vérifier que la hiérarchie texte 3 opacités s'applique sur les métadonnées événements
- [ ] Tester en light mode (le thème dark mode pourra être ajouté si besoin)
- [ ] Capture d'écran avant/après pour validation visuelle

---

*Fin du document v2.*
*Pour modifications futures, créer v3 sans patch notes (chaque version autonome et lisible indépendamment).*