# Epic 2: Homepage & Design System - Stories

Enable users to experience a beautiful, branded, accessible homepage with full navigation on any device.

**User Outcome:** Users land on an inspiring terracotta/beige themed homepage with hero section, navigation, and complete design system for all future components.

**FRs covered:** FR20-FR25, NFR-AC1 à AC10, NFR-C1 à C4, UX-DR1 à UX-DR32, ARCH-38 à ARCH-40

---

## Story 2.1: Tailwind Design System Configuration

As a developer,
I want Tailwind CSS configured with custom terracotta/beige theme tokens and responsive breakpoints,
So that all components use consistent branding and layouts.

**Acceptance Criteria:**

**Given** Rails 8 app with tailwindcss-rails gem installed
**When** I configure Tailwind design system
**Then** `tailwind.config.js` exists with custom theme:

```javascript
module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/javascripts/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'terracotta': '#C2623F',      // Primary brand color
        'terracotta-light': '#D97E5C',
        'terracotta-dark': '#A5502F',
        'beige': '#F5E6D3',            // Secondary color
        'beige-dark': '#E8D4BB',
        'dark-bg': '#1A1A1A',          // Near-black background
      },
      fontFamily: {
        'script': ['Georgia', 'serif'],  // Elegant italic for titles/logo
        'sans': ['Inter', 'system-ui', 'sans-serif'],  // Body text
      },
      screens: {
        'xs': '390px',   // iPhone 12 Pro mobile reference
        'sm': '640px',
        'md': '768px',   // Tablet
        'lg': '1024px',  // Desktop sidebar visible
        'xl': '1280px',
        '2xl': '1728px', // MacBook Pro 16" reference
      }
    }
  },
  plugins: []
}
```

**And** `app/assets/stylesheets/application.tailwind.css` includes:
```css
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Custom layer for reusable patterns */
@layer components {
  .btn-primary {
    @apply bg-terracotta hover:bg-terracotta-dark text-white font-medium py-3 px-6 rounded-lg transition-colors duration-200;
  }
}
```

**And** Tailwind CSS compiles without errors: `rails tailwindcss:build`
**And** Custom colors work in views: `<div class="bg-terracotta text-white">`
**And** Responsive breakpoints work: `<div class="w-full lg:w-1/3">` (full-width mobile, 1/3 desktop)
**And** Font families apply correctly: `<h1 class="font-script italic">AU JOUR duy</h1>`
**And** `.btn-primary` utility class works: `<button class="btn-primary">AGENDA</button>`

---

## Story 2.2: Reusable Tag/Pill Component

As a user,
I want to see color-coded tags on events (atelier, stage, gratuit, en ligne),
So that I can quickly identify event types at a glance.

**Acceptance Criteria:**

**Given** Tailwind design system configured from Story 2.1
**When** I create a reusable tag component
**Then** `app/views/shared/_tag.html.erb` partial exists:

```erb
<%# locals: text, variant %>
<span class="inline-block rounded-full px-3 py-1 text-sm font-medium <%= tag_variant_class(variant) %>">
  <%= text %>
</span>
```

**And** `app/helpers/tags_helper.rb` exists with variant mapping:

```ruby
module TagsHelper
  def tag_variant_class(variant)
    case variant.to_s
    when 'atelier'
      'bg-terracotta text-white'
    when 'stage'
      'bg-terracotta-light text-white'
    when 'gratuit'
      'bg-green-100 text-green-800'
    when 'en_ligne'
      'bg-blue-100 text-blue-800'
    when 'en_presentiel'
      'bg-gray-200 text-gray-800'
    else
      'bg-gray-100 text-gray-700'
    end
  end
end
```

**And** Tag component renders correctly: `<%= render 'shared/tag', text: 'Atelier', variant: 'atelier' %>`
**And** Tags are visually distinct with proper colors:
- Atelier: terracotta background (#C2623F)
- Stage: light terracotta (#D97E5C)
- Gratuit: soft green (green-100)
- En ligne: blue/teal (blue-100)
- En présentiel: neutral gray (gray-200)

**And** Tags use Tailwind classes: `rounded-full px-3 py-1 text-sm`
**And** Accessible: color contrast meets WCAG 2.1 AA (4.5:1 minimum for normal text)
**And** Tags are tested with Lighthouse Accessibility > 90

---

## Story 2.3: PagesController & Hero Homepage

As a visitor,
I want to land on an inspiring homepage with hero section and clear CTAs,
So that I understand the site purpose and can navigate to key sections.

**Acceptance Criteria:**

**Given** Tailwind design system and tag component exist
**When** I create the homepage
**Then** PagesController exists (`app/controllers/pages_controller.rb`) with actions: home, about, contact

**Routes configured (`config/routes.rb`):**
```ruby
root 'pages#home'
get '/a-propos', to: 'pages#about', as: :about
get '/contact', to: 'pages#contact'
get '/proposants', to: 'pages#proposants', as: :proposants  # "Publier ateliers" form
get '/actualites', to: 'pages#actualites', as: :actualites  # Stub page
```

**Homepage view (`app/views/pages/home.html.erb`):**
```erb
<%= render 'shared/hero' %>

<section class="container mx-auto px-4 py-12">
  <div class="grid grid-cols-1 md:grid-cols-2 gap-4 max-w-4xl mx-auto">
    <%= link_to "AGENDA", evenements_path, class: "btn-primary text-center" %>
    <%= link_to "PUBLIER ATELIERS", proposants_path, class: "btn-primary text-center" %>
    <%= link_to "ACTUALITÉS", actualites_path, class: "btn-primary text-center" %>
    <%= link_to "QUI EST DUY", about_path, class: "btn-primary text-center" %>
    <%= link_to "ME CONTACTER", contact_path, class: "btn-primary text-center" %>
    <%= link_to "DONATIONS", "#", class: "btn-primary text-center", target: "_blank" %>
  </div>
</section>
```

**Hero partial (`app/views/shared/_hero.html.erb`):**
```erb
<section class="relative min-h-screen lg:min-h-[600px] flex items-center justify-center bg-dark-bg text-white">
  <%# Background dancer photo - placeholder for now %>
  <div class="absolute inset-0 bg-gradient-to-b from-transparent to-dark-bg/50"></div>

  <div class="relative z-10 text-center px-4">
    <h1 class="font-script italic text-4xl md:text-6xl mb-6">AU JOUR duy</h1>
    <p class="text-xl md:text-2xl italic max-w-3xl mx-auto">
      Agenda de référence des pratiques de danse exploratoires et non-performatives en France.
      "Quel atelier ce soir à Paris ?" — ce que Google et Facebook ne savent pas faire.
    </p>
  </div>
</section>
```

**And** Stimulus carousel controller exists (`app/assets/javascripts/controllers/carousel_controller.js`):
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]

  connect() {
    // Placeholder for carousel functionality
    // Will be enhanced when hero photos are added
    console.log("Carousel controller connected")
  }
}
```

**And** About/Contact/Proposants pages are stubs with basic layout:
```erb
<%# app/views/pages/about.html.erb %>
<div class="container mx-auto px-4 py-12">
  <h1 class="font-script italic text-4xl mb-6">Qui est Duy</h1>
  <p>Page à compléter...</p>
</div>
```

**And** Homepage renders at `/` without errors
**And** CTA grid responsive: 1 column mobile (< 768px), 2 columns desktop (>= 768px)
**And** All buttons use terracotta styling via `.btn-primary` class
**And** Hero section is full-height on mobile (min-h-screen), fixed height on desktop (min-h-[600px])
**And** Text is readable on dark background (white text on dark-bg)

---

## Story 2.4: Responsive Navigation (Desktop & Mobile)

As a visitor,
I want to navigate between site sections easily on any device,
So that I can access all pages from desktop navbar or mobile hamburger menu.

**Acceptance Criteria:**

**Given** PagesController and homepage exist
**When** I create responsive navigation
**Then** `app/views/layouts/application.html.erb` includes navigation partial:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>3 Graces - Agenda danse exploratoire</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>
  <body class="bg-beige">
    <%= render 'shared/navbar' %>
    <%= render 'shared/mobile_drawer' %>

    <main>
      <%= yield %>
    </main>
  </body>
</html>
```

**Desktop navbar (`app/views/shared/_navbar.html.erb`):**
```erb
<nav class="hidden lg:block bg-dark-bg text-white py-4 sticky top-0 z-50">
  <div class="container mx-auto px-4 flex items-center justify-between">
    <%# Logo %>
    <%= link_to root_path, class: "font-script italic text-2xl" do %>
      AU JOUR duy
    <% end %>

    <%# Navigation links %>
    <div class="flex items-center gap-6">
      <%= link_to "Accueil", root_path, class: "hover:text-terracotta transition-colors" %>
      <%= link_to "Agenda", evenements_path, class: "hover:text-terracotta transition-colors" %>
      <%= link_to "Newsletter", "#", class: "hover:text-terracotta transition-colors", data: { action: "click->newsletter#open" } %>
      <%= link_to "L'espace des proposants", proposants_path, class: "hover:text-terracotta transition-colors" %>
    </div>
  </div>
</nav>
```

**Mobile header with hamburger (`app/views/shared/_mobile_drawer.html.erb`):**
```erb
<div class="lg:hidden" data-controller="mobile-drawer">
  <%# Mobile header %>
  <header class="bg-dark-bg text-white py-4 px-4 flex items-center justify-between sticky top-0 z-50">
    <%# Logo %>
    <%= link_to root_path, class: "font-script italic text-xl" do %>
      AU JOUR duy
    <% end %>

    <%# Icons %>
    <div class="flex items-center gap-4">
      <button data-action="click->mobile-drawer#toggle" class="text-2xl">
        ☰
      </button>
    </div>
  </header>

  <%# Drawer overlay %>
  <div data-mobile-drawer-target="overlay" class="hidden fixed inset-0 bg-black/50 z-40" data-action="click->mobile-drawer#close"></div>

  <%# Drawer panel %>
  <aside data-mobile-drawer-target="panel" class="hidden fixed top-0 right-0 h-full w-64 bg-dark-bg text-white z-50 p-6 transform transition-transform">
    <button data-action="click->mobile-drawer#close" class="absolute top-4 right-4 text-2xl">×</button>

    <nav class="mt-12 flex flex-col gap-4">
      <%= link_to "Accueil", root_path, class: "text-lg hover:text-terracotta transition-colors" %>
      <%= link_to "Agenda", evenements_path, class: "text-lg hover:text-terracotta transition-colors" %>
      <%= link_to "S'inscrire à la newsletter", "#", class: "text-lg hover:text-terracotta transition-colors" %>
      <%= link_to "Liens", "#", class: "text-lg hover:text-terracotta transition-colors" %>
      <%= link_to "L'espace des proposants", proposants_path, class: "text-lg hover:text-terracotta transition-colors" %>
    </nav>
  </aside>
</div>
```

**Mobile drawer Stimulus controller (`app/assets/javascripts/controllers/mobile_drawer_controller.js`):**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  toggle() {
    this.overlayTarget.classList.toggle("hidden")
    this.panelTarget.classList.toggle("hidden")
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.panelTarget.classList.add("hidden")
  }
}
```

**And** Desktop navbar visible on screens >= 1024px (lg breakpoint)
**And** Mobile header + drawer visible on screens < 1024px
**And** Hamburger icon (☰) triggers drawer slide-in from right
**And** Drawer overlay (semi-transparent black) closes drawer when clicked
**And** Close button (×) in drawer closes it
**And** Navigation links work in both desktop and mobile views
**And** Navbar is sticky (sticky top-0 z-50) on desktop
**And** Mobile drawer has slide-in animation (transform transition-transform)
**And** Accessible: keyboard navigation works (Tab, Enter, Esc to close drawer)

---

## Story 2.5: WCAG 2.1 AA Compliance & Accessibility Audit

As a visitor with disabilities,
I want the site to be fully accessible via keyboard and screen readers,
So that I can navigate and use all features independently.

**Acceptance Criteria:**

**Given** Homepage, navigation, and design system exist
**When** I audit accessibility
**Then** the following WCAG 2.1 AA standards are met:

**Color Contrast (NFR-AC2, NFR-AC3):**
- Normal text: minimum 4.5:1 contrast ratio
  - Terracotta (#C2623F) on white: tested and passes
  - White text on dark-bg (#1A1A1A): tested and passes
- Large text (18pt+): minimum 3:1 contrast ratio
  - Hero title white on dark background: tested and passes
- Tags: all color combinations tested with WebAIM Contrast Checker

**Keyboard Navigation (NFR-AC4):**
- All interactive elements focusable via Tab
- Buttons trigger via Enter key
- Drawer closes via Esc key
- Focus indicators visible (outline-2 outline-terracotta on focus)

**Semantic HTML5 (NFR-AC7):**
```erb
<header>
  <nav>
    <ul><li><a>...</a></li></ul>
  </nav>
</header>
<main>
  <section>
    <h1>...</h1>
  </section>
</main>
<footer>...</footer>
```

**ARIA labels (NFR-AC5):**
- Hamburger button: `aria-label="Open navigation menu"`
- Close button in drawer: `aria-label="Close navigation menu"`
- Mobile drawer: `aria-hidden="true"` when closed
- Skip to main content link (hidden, appears on focus): `<a href="#main" class="sr-only focus:not-sr-only">Skip to main content</a>`

**Images alt text (NFR-AC6):**
- All decorative images: `alt=""`
- All meaningful images: descriptive alt text
- Hero background: CSS background, not requiring alt

**Focus indicators (NFR-AC8):**
```css
/* In application.tailwind.css */
@layer base {
  a:focus, button:focus {
    @apply outline-2 outline-offset-2 outline-terracotta;
  }
}
```

**And** Lighthouse Accessibility audit score > 90 (meets NFR-AC9)
**And** Screen reader test (NVDA or VoiceOver) passes: all content readable, navigation announced correctly (meets NFR-AC10)
**And** Keyboard-only navigation works: can navigate entire site with Tab/Shift+Tab/Enter/Esc
**And** Skip link appears on Tab focus at top of page
**And** All interactive elements have visible focus state

---

## Epic 2 Summary

**Total Stories:** 5

**All requirements covered:**
- FR20-FR25: Responsive layouts (Stories 2.1, 2.3, 2.4)
- NFR-AC1-AC10: Full WCAG 2.1 AA compliance (Story 2.5)
- NFR-C1-C4: Browser compatibility via Tailwind CSS (Stories 2.1-2.5)
- UX-DR1-UX-DR32: Design tokens, components, navigation, responsive breakpoints (Stories 2.1-2.5)
- ARCH-38-ARCH-40: PagesController, hero, navigation, Stimulus controllers (Stories 2.3, 2.4)

**Key Deliverables:**
- Tailwind design system with terracotta/beige theme
- Reusable tag component
- Homepage with hero section + CTA grid
- Desktop navbar + mobile drawer navigation
- Full WCAG 2.1 AA accessibility compliance
