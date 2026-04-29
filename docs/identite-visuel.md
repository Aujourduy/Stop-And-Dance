# Identité Visuelle Duy — Système de Design v4

> **Document de référence brand pour toutes les plateformes.**
> **Date** : avril 2026 · **Status** : validé pour implémentation

---

## 1. Vue d'ensemble

Identité visuelle unifiée pour Stop & Dance, Aujourduy.fr, supports DCAV, Spira5, chaîne YouTube, présence Facebook, et tous futurs supports.

### Distinctive Brand Assets

Trois éléments de reconnaissance instantanée (modèle Byron Sharp, *How Brands Grow*) :

1. **Terracotta `#BF462E`** — couleur primary identitaire
2. **Fraunces SOFT 45** — typographie display variable, calibration unifiée signature
3. **Bleu chàm `#1F3158`** — contrepoint culturel, indigo traditionnel vietnamien

Tout le reste du système est en service de ces 3 assets.

### Polarité assumée

La palette globale (terre + deux verts + crème + chàm) communique une posture **contemplative organique avec contrepoint de précision**. Cohérent avec le positionnement "Témoin de ton rayonnement" et "Pédagogue du vivant". Le tranchant Nasreddine et l'énergie Promoteur passent par la voix copywriting et le Corail vif en accent CTA — pas par la palette ni par la typographie qui restent unifiées.

---

## 2. Palette — 10 couleurs

### Couleurs principales (60-30-10)

| Nom | Hex | RGB | Rôle | Usage |
|-----|-----|-----|------|-------|
| **Terracotta** | `#BF462E` | rgb(191, 70, 46) | Primary | Identité forte, boutons d'action principale, titres porteurs, identifiants section |
| **Eucalyptus** | `#6C9D9A` | rgb(108, 157, 154) | Secondary cool | Teal sophistiqué — sites système, contenu intellectuel, contraste structurel froid |
| **Corail vif** | `#F2815A` | rgb(242, 129, 90) | Accent (10%) | CTA exclusivement. Jamais en aplat large. |

### Couleurs de soutien

| Nom | Hex | RGB | Rôle | Usage |
|-----|-----|-----|------|-------|
| **Sauge** | `#7B937A` | rgb(123, 147, 122) | Accent warm | Vert végétal herbacé — visuels chauds, communauté, présence vivante, accents sur fonds Terracotta/Sable |
| **Argile rose** | `#BB8777` | rgb(187, 135, 119) | Soutien chaud | Hover states, micro-éléments, transitions. Jamais en aplat large. |
| **Sable** | `#B29D7E` | rgb(178, 157, 126) | Neutre chaud | Sections calmes, zones non-pressantes, fonds doux |
| **Bleu chàm** | `#1F3158` | rgb(31, 49, 88) | Contrepoint précision | Pull-quotes intellectuels, framework Spira5, sections "rigueur", liens de profondeur, bannière pro |

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

Sauge, Argile rose, Bleu chàm, Brun profond sont **hors quota 60-30-10** : ils servent des fonctions ponctuelles précises.

### Distinction Eucalyptus vs Sauge — règle d'usage critique

Le système Duy contient **deux verts**, chacun avec une fonction distincte non-interchangeable :

| | **Eucalyptus** `#6C9D9A` | **Sauge** `#7B937A` |
|---|---|---|
| Famille chromatique | Teal (vert-bleu) | Vert herbacé (vert-jaune) |
| Registre sémantique | **Cool, sophistiqué, intellectuel** | **Warm, vivant, herbacé** |
| Match identité | Spira5, DCAV, sites système | Stop & Dance, communauté, terre |
| Usage typique | Boutons secondaires sites, contenus intellectuels, états info | Accents sur fonds chauds (Terracotta, Sable, Argile), visuels communauté |
| Tension chromatique recherchée | Contre Terracotta : cool vs warm | Avec Terracotta : harmonie chaude |

**Règle d'usage** : ne jamais mélanger Eucalyptus et Sauge dans un même visuel. Choisir le registre selon le contexte ; si tension chaud/froid forte voulue, Bleu chàm fait mieux le contrepoint cool qu'Eucalyptus.

---

## 3. Typographie

### Polices

- **Fraunces** (display, headlines, titres, body éditorial long) — serif variable contemporain par Undercase Type. Réglage unifié : **`SOFT 45` partout**.
- **Inter** (body courant, UI, métadonnées, chiffres, formulaires) — sans-serif neutre haute lisibilité par Rasmus Andersson.

### Règle d'or — calibration unifiée Fraunces

**Tous les textes en Fraunces utilisent SOFT 45**, sur tous les supports, dans tous les contextes. Pas de modulation par axe variable. Aucun registre alternatif (Dansant / Profond / Impact) n'est défini.

La modulation s'opère uniquement par :
- **Weight** : 400 (regular), 500 (medium), 700 (bold), 900 (black)
- **Style** : roman (droit) ou italic
- **Taille** : selon l'échelle ci-dessous

```css
font-family: 'Fraunces', Georgia, serif;
font-variation-settings: 'SOFT' 45;
```

L'axe WONK n'est plus exploité comme signal stratégique. Il reste à 0 par défaut. Si une version technique de Fraunces utilisée ne supporte pas l'axe WONK, aucun impact sur le rendu identitaire.

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

### Usages italique Fraunces

L'italique Fraunces (toujours en SOFT 45) est réservé aux contextes éditoriaux suivants :

- **Pull-quotes** (citations Baret, attributions philosophiques)
- **Taglines** sous titres principaux
- **Accents éditoriaux** (mots emphatiques dans un titre, sous-titre poétique)
- **Attributions** (nom de l'auteur d'une citation, nom d'une œuvre)

Italique non utilisé en body courant.

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
        sauge: '#7B937A',
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
        duy: {
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
          "success": "#7B937A",
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
<html data-theme="duy">
```

### Règle CSS globale Fraunces (à ajouter dans le CSS principal)

Pour garantir SOFT 45 sur toute occurrence de Fraunces sans avoir à le répéter dans chaque composant :

```css
.font-display,
[class*="font-display"] {
  font-variation-settings: 'SOFT' 45;
}
```

Ou via une utility class Tailwind custom dans `tailwind.config.js` :

```js
// Dans theme.extend, ajouter :
fontVariationSettings: {
  'soft': "'SOFT' 45",
}
```

### Chargement des polices

**Option A — Google Fonts (CDN, plus simple)**

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght,SOFT@0,9..144,400..900,0..100;1,9..144,400..900,0..100&family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
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
  --color-sauge: #7B937A;
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
  --font-display-soft: 'SOFT' 45;
}
```

---

## 6. Application par plateforme

### 6.1 Site Stop & Dance / Aujourduy.fr

- Fond global : Crème lumière `#F8F3EA`
- Headers : Fraunces 700 SOFT 45 en Terracotta ou Brun profond
- CTA primaires : Terracotta avec texte Crème
- CTA secondaires : Eucalyptus
- Citations Baret / Spira5 : Fraunces Italic 400 SOFT 45 en Bleu chàm avec `border-left: 3px solid #1F3158`
- Tags "vivant" / "disponible" / "communauté" : Sauge sur fond Crème
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
| Titre principal | Fraunces 700 SOFT 45, 80-120px selon longueur (4-8 mots max), Terracotta `#BF462E` |
| Trait signature sous titre | Bleu chàm `#1F3158`, 2px d'épaisseur, 32px de long |
| Tagline | Fraunces Italic 400 SOFT 45, 24-32px, Brun profond à 70% opacité |
| Signature URL | Inter 12px en bas à droite, Brun à 40% |
| Logo Aujourduy calligraphique | Optionnel, en haut à droite ou centré au-dessus du titre |

**Règle critique** : aucune information critique (titre, tagline, URL) en dehors de la safe zone 1546 × 423. Les extensions latérales sont décoratives uniquement.

### 6.3 YouTube — Miniatures (thumbnails)

| Paramètre | Valeur |
|-----------|--------|
| Dimensions | 1280 × 720 px |
| Police | Fraunces 900 SOFT 45 (lisibilité petit format) |
| Taille texte hero | 140-180px, 4-6 mots max |
| Couleur option A | Crème `#F8F3EA` sur fond Brun profond `#2D231C` |
| Couleur option B | Brun profond `#2D231C` sur fond Crème `#F8F3EA` |
| Accent | Terracotta sur 1 mot ou élément graphique, ≤ 10% de la surface |
| Visage | Portrait à droite, regard caméra, expression alignée au sujet |

**Anti-patterns thumbnails** : pas de flèche rouge, pas de bouche grand ouverte stupéfaite, pas de fond explosé multicolore, pas de halo coloré, pas de texte en cercle.

### 6.4 Facebook — Bannière PRO

| Paramètre | Valeur |
|-----------|--------|
| Dimensions | 1640 × 856 px |
| Safe zone mobile (toute info critique) | 820 × 312 px centré (x: 410-1230, y: 272-584) |
| Fond | Bleu chàm `#1F3158` (registre grave méditatif) |
| Eyebrow | Inter 500 caps tracking 4px, 22px, Crème à 70% |
| Phrase principale | Fraunces 700 SOFT 45, 39px max (pour tenir dans safe zone), Crème lumière + accent Corail vif sur mot-clé |
| Trait signature | Crème à 70%, 36×3 px (Bleu chàm disparaîtrait sur fond chàm) |
| Signature | Fraunces Italic 400 SOFT 45, 22px, Crème à 70% |

**Règle critique safe zone** : Facebook 2026 affiche la cover sur 3 viewports différents (desktop 820×312 visible, mobile ~640×360, tablette variable). La safe zone "tous appareils" = intersection = 820×312 centré. Tout le contenu critique doit tenir dedans.

**Règle dimensionnement phrase** : la phrase doit être calibrée pour que la ligne la plus longue ne dépasse pas 780 px (820 safe zone - 40 px de marge interne). À Fraunces 700 SOFT 45, cela limite à environ 39-41 px pour une phrase d'une quarantaine de caractères.

### 6.5 Facebook — Bannière PERSO (pour profils utilisés en pro déguisé)

| Paramètre | Valeur |
|-----------|--------|
| Dimensions | 1640 × 856 px |
| Safe zone mobile | 820 × 312 px centré (identique à pro) |
| Fond | Terracotta `#BF462E` (registre chaleur lumineuse, contrepoint avec PRO chàm) |
| Eyebrow | Inter 500 caps tracking 4px, 22px, Crème à 70% |
| Phrase principale | Fraunces 700 SOFT 45, 39px max, Crème lumière |
| Accent sur mot-clé | Sauge `#7B937A` weight 900 (le poids visuel compense le contraste faible 1.52:1) |
| Trait signature | Bleu chàm `#1F3158`, 36×3 px |
| Signature | Fraunces Italic 400 SOFT 45, 22px, Crème à 70% |

**Logique de différenciation PRO/PERSO** : même phrase, palette inversée. PRO grave (chàm), PERSO chaleureuse (Terracotta). Continuité de la phrase, distinction par fond. Cohérence Byron Sharp distinctive brand assets : reconnaissance immédiate des deux côtés sans confusion.

### 6.6 Facebook — Posts carrés et stories

| Paramètre | Carré | Story |
|-----------|-------|-------|
| Dimensions | 1080 × 1080 px | 1080 × 1920 px |
| Marge interne minimum | 80px | 90px |
| Police titre | Fraunces 700-900 SOFT 45 selon impact | Fraunces 900 SOFT 45 |
| Hiérarchie texte | Eyebrow Inter caps + titre Fraunces + body Inter 400 | idem |
| Palette par visuel | 1 couleur dominante max + 1 accent | idem |
| CTA | Corail vif `#F2815A` rectangle bouton, texte Crème, Inter 500, padding 16px | idem |

**Règle critique** : jamais 4 couleurs sur un même visuel social. Discipline 60-30-10 stricte.

### 6.7 Supports DCAV (sales page, workbooks, présentations)

- Sales page : Fraunces SOFT 45 (toutes graisses) + Bleu chàm pull-quotes + Brun profond body
- Documents print : Crème ou Sable ombré en fond, Brun en texte
- Workbooks : hiérarchie 3 opacités stricte
- Présentations : Fraunces 900 SOFT 45 titres, Inter body, Bleu chàm pour frameworks Spira5

---

## 7. Assets brand à fournir séparément

Pour utilisation avec un outil de génération visuelle (Claude Design, Canva, Figma) ou pour intégration dans un codebase, fournir en complément du présent document :

- **Logo Aujourduy calligraphique** : SVG ou PNG transparent haute résolution. Mark distinctif à conserver intact dans tous les visuels brand. Ne jamais remplacer par "Aujourduy" en Fraunces — la calligraphie EST l'asset.
- **Photos authentiques** : portrait Duy (regard caméra, expression naturelle), scènes de danse libre, lieux d'événements. Jamais de photo stock générique.
- **Captures du site Aujourduy.fr** : 2-3 screenshots des pages clés pour référence visuelle de l'esthétique existante.
- **Références visuelles d'inspiration** (mood board) : Aesop, Defector, Are.na, textile chàm vietnamien (H'mong/Tày). Ces références ancrent le ton visuel sans en faire des modèles à copier.

---

## 8. Anti-patterns — À ne JAMAIS faire

- Utiliser **noir pur `#000`** en texte → toujours Brun profond `#2D231C`
- Utiliser **blanc pur `#FFFFFF`** en fond → toujours Crème lumière `#F8F3EA`
- Mettre **Corail vif en aplat large** → l'accent perd sa fonction (10% strict)
- Mettre **Bleu chàm en CTA** → Bleu chàm = profondeur intellectuelle, pas appel à action
- Mettre **Eucalyptus en texte body** → contraste insuffisant (2.7:1), usage graphique seulement
- Mettre **Sauge en texte body sur Crème** → contraste insuffisant, usage accent uniquement
- **Mélanger Eucalyptus et Sauge dans un même visuel** → confusion sémantique des registres cool/warm
- Mélanger **Argile rose et Sauge en proportions égales** → tension chromatique sans signal
- Utiliser **Fraunces avec un autre SOFT que 45** → calibration unifiée, pas de modulation par axe
- Mélanger **Fraunces + une autre police serif** → toujours Fraunces (display) + Inter (sans), point.
- Bolds en weight 600 partout → 500 par défaut UI, 700 réservé aux titres Fraunces
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
| Crème lumière sur Terracotta | 4.7:1 | AA (texte ≥ 18px ou ≥ 14px gras) |
| Terracotta sur Crème lumière | 4.7:1 | AA (texte ≥ 18px ou ≥ 14px gras) |
| Eucalyptus sur Crème lumière | 2.7:1 | ❌ Échec — graphique uniquement |
| Sauge sur Crème lumière | 3.0:1 | ⚠️ Limite — graphique uniquement |
| Sauge sur Terracotta | 1.5:1 | ❌ Échec WCAG — accent décoratif uniquement, compenser par weight 900 |
| Eucalyptus sur Terracotta | 1.7:1 | ❌ Échec WCAG — non utilisable |
| Terracotta sur Brun profond | 3.0:1 | ❌ Échec — non utilisable |

**Règles de contraste à respecter** :
- Texte body sur Crème : utiliser Brun profond uniquement
- Eucalyptus / Sauge : couleurs d'éléments graphiques (icônes, fonds, bordures, accents) — jamais texte body sur Crème
- Sauge en accent sur Terracotta : utiliser weight 900 pour compenser le faible contraste WCAG (le poids visuel crée la hiérarchie quand la couleur seule ne suffit pas)
- Terracotta en texte : taille large uniquement (≥ 18px), sur Crème
- Bleu chàm : excellente lisibilité partout sur Crème, idéal pour pull-quotes lisibles

### Test "0.3 seconde" (Sharp)

À chaque nouveau visuel, demander : *"En 0.3 seconde, ce visuel est-il reconnaissable comme Duy ?"*
- Si Terracotta dominant (ou contraste fort terre/chàm) + Fraunces SOFT 45 visible → OUI
- Sinon → revoir

### Test Byron Katie sur formulations

Avant publication d'un visuel important : *"Est-ce que cette formulation, présentée ainsi, est vraie ?"*
Si non → reformuler. Si oui → publier.

---

## 10. Évolutions futures

Cette palette est conçue pour absorber sans rupture les futurs produits :

- **DCAV** : palette identique avec dominante Bleu chàm + Brun profond pour gravité philosophique, Eucalyptus en accent froid
- **Spira5** : palette identique avec Bleu chàm dominant + Eucalyptus pour précision modélisation
- **Stop & Dance** : palette identique avec Terracotta + Corail dominants + Sauge pour énergie communautaire vivante
- **Personal brand Duy** : palette complète, équilibrée

Si un futur produit demande une palette distincte (ex: marque sœur), maintenir au minimum **Fraunces SOFT 45** comme constante typographique pour bridge identitaire.

---

## 11. Rationnel des décisions

**Terracotta primary** — chaleur, ancrage, terre, intensité. Aligné avec "Du chaos au vivant" et danse incarnée. Distinctif sur le marché coaching/wellness français saturé.

**Fraunces SOFT 45 unifié** — variable serif contemporain calibré à une valeur précise et intentionnelle. Le choix de 45 (et non 50 par défaut) signale le contrôle calibré du créateur. La règle unifiée garantit cohérence parfaite sur tous les supports sans arbitrage à chaque visuel. Modulation expressive uniquement par weight (400-900) et style (italic), suffisant pour couvrir tous les registres communicationnels.

**Bleu chàm** — résonance vietnamienne (chàm = indigo traditionnel des textiles H'mong/Tày), contrepoint chaud/froid avec Terracotta (combo structurellement la plus forte en branding), précision mathématique/intellectuelle, distinctivité immédiate.

**Deux verts distincts (Eucalyptus + Sauge)** — Eucalyptus est un teal sophistiqué (vert-bleu) qui sert le registre cool-intellectuel. Sauge est un vert herbacé (vert-jaune) qui sert le registre warm-vivant. Ils ne sont pas redondants chromatiquement : leurs compositions RGB diffèrent significativement (Eucalyptus a presque autant de bleu que de vert, Sauge a clairement le vert dominant). Maintenir les deux permet d'adapter le registre selon le contexte sans casser la cohérence systémique.

**Crème lumière + Brun profond** — refus du noir/blanc clinique, posture "vivant" même dans les contrastes. Contraste 14.4:1 (zone optimale lecture longue, anti-fatigue par rapport au noir pur sur blanc à 21:1).

**Hiérarchie 3 opacités** — système éprouvé (Aesop, Linear, Stripe). Couvre 95% des besoins texte sans introduire de couleurs supplémentaires.

**Inter en body** — neutralité haute qualité, contemporary tech-aware, pair avec Fraunces sans tension visuelle (Fraunces porte la personnalité, Inter porte la fonction).

**Logique PRO/PERSO Facebook** — différencier les deux profils par palette inversée (chàm vs Terracotta) tout en gardant la même phrase et le même système typographique. Permet la reconnaissance immédiate de la marque sur les deux profils sans effet "doublon" qui dévaloriserait l'investissement perçu.

---

## 12. Checklist d'intégration Claude Code

À cocher lors de l'implémentation sur Stop & Dance :

- [ ] Ajouter Fraunces et Inter via `@fontsource` (Option B recommandée)
- [ ] Mettre à jour `tailwind.config.js` avec le bloc complet (section 4) — **Sauge incluse**
- [ ] Activer le thème `data-theme="duy"` dans `application.html.erb`
- [ ] Créer `app/assets/stylesheets/_brand.css` avec les CSS variables (section 5) — **Sauge incluse**
- [ ] Ajouter la règle CSS globale Fraunces SOFT 45 (section 4)
- [ ] Vérifier que les classes DaisyUI existantes (`btn-primary`, `btn-accent`, etc.) reflètent la nouvelle palette
- [ ] Tester le contraste sur les pages clés (homepage, page événement, formulaire de recherche)
- [ ] Mettre à jour les composants custom qui utilisaient des couleurs hardcodées
- [ ] Vérifier que la hiérarchie texte 3 opacités s'applique sur les métadonnées événements
- [ ] Vérifier que SOFT 45 est appliqué partout où Fraunces est utilisé
- [ ] Vérifier qu'Eucalyptus et Sauge ne se mélangent jamais dans un même composant
- [ ] Capture d'écran avant/après pour validation visuelle

---

*Fin du document v4.*
*Pour modifications futures, créer v5 sans patch notes (chaque version autonome et lisible indépendamment).*