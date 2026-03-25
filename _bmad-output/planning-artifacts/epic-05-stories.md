# Epic 5: Event Filtering & Search - Stories

Enable users to filter events by multiple criteria to find exactly what they're looking for.

**User Outcome:** Users can filter events by date, type, format, price to narrow down the agenda and plan their dance activities.

**FRs covered:** FR3-FR6, (FR7-FR8 post-MVP), UX-DR15 à UX-DR19

---

## Story 5.1: Filter Panel Component (Desktop Sidebar, Mobile Overlay)

As a visitor,
I want to access event filters easily on any device,
So that I can narrow down the event list to events that interest me.

**Acceptance Criteria:**

**Given** event list page loaded
**When** I view filters
**Then** `app/views/shared/_filters.html.erb` partial exists:

```erb
<div class="bg-white rounded-lg shadow-sm p-6 sticky top-4"
     data-controller="filters">

  <%# Filter header %>
  <div class="flex items-center justify-between mb-6 bg-terracotta text-white -mx-6 -mt-6 px-6 py-4 rounded-t-lg">
    <h2 class="font-script italic text-2xl">Filtrez l'agenda</h2>
    <%# Close button only visible on mobile overlay (hidden on desktop sidebar) %>
    <button data-action="click->filters#close"
            class="lg:hidden text-2xl">
      &times;
    </button>
  </div>

  <%= form_with url: evenements_path,
                method: :get,
                data: {
                  controller: "auto-submit",
                  turbo_frame: "events-list"
                },
                class: "space-y-6" do |f| %>

    <%# Type & Format filters (2-column grid) %>
    <div>
      <h3 class="font-medium mb-3">Type et format</h3>
      <div class="grid grid-cols-2 gap-3">
        <%= f.check_box :en_presentiel,
                        { class: "rounded text-terracotta focus:ring-terracotta" },
                        "true", nil %>
        <%= f.label :en_presentiel, "En présentiel", class: "ml-2" %>

        <%= f.check_box :stage,
                        { class: "rounded text-terracotta focus:ring-terracotta" },
                        "true", nil %>
        <%= f.label :stage, "Stage", class: "ml-2" %>

        <%= f.check_box :en_ligne,
                        { class: "rounded text-terracotta focus:ring-terracotta" },
                        "true", nil %>
        <%= f.label :en_ligne, "En ligne", class: "ml-2" %>

        <%= f.check_box :gratuit,
                        { class: "rounded text-terracotta focus:ring-terracotta" },
                        "true", nil %>
        <%= f.label :gratuit, "Gratuit", class: "ml-2" %>

        <%= f.check_box :atelier,
                        { class: "rounded text-terracotta focus:ring-terracotta" },
                        "true", nil %>
        <%= f.label :atelier, "Atelier", class: "ml-2" %>
      </div>
    </div>

    <%# Date filter %>
    <div>
      <h3 class="font-medium mb-3">Date</h3>
      <%= f.label :date_debut, "À partir du", class: "block text-sm mb-1" %>
      <%= f.date_field :date_debut,
                       class: "w-full rounded border-gray-300 focus:border-terracotta focus:ring-terracotta",
                       placeholder: "JJ/MM/AAAA" %>
    </div>

    <%# Geographic filter (basic MVP, full geocoding post-MVP) %>
    <div>
      <h3 class="font-medium mb-3">Lieu</h3>
      <%= f.label :lieu, "Adresse, ville...", class: "block text-sm mb-1" %>
      <%= f.text_field :lieu,
                       class: "w-full rounded border-gray-300 focus:border-terracotta focus:ring-terracotta mb-3",
                       placeholder: "Paris, Lyon..." %>

      <%= f.label :distance, "Distance (km)", class: "block text-sm mb-1" %>
      <%= f.number_field :distance,
                         class: "w-full rounded border-gray-300 focus:border-terracotta focus:ring-terracotta",
                         placeholder: "Ex: 20",
                         disabled: true %>
      <p class="text-xs text-gray-500 mt-1">Géolocalisation disponible prochainement</p>
    </div>

    <%# Submit button %>
    <%= f.submit "Appliquer",
                 class: "w-full bg-terracotta text-white font-medium py-3 rounded hover:bg-terracotta-dark transition-colors cursor-pointer" %>

    <%# Reset button %>
    <%= link_to "Réinitialiser",
                evenements_path,
                data: { turbo_frame: "events-list" },
                class: "block text-center text-terracotta hover:underline mt-2" %>
  <% end %>
</div>
```

**And** `app/assets/javascripts/controllers/filters_controller.js` exists:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  close() {
    // Close mobile filter overlay
    this.element.closest('.filter-overlay')?.remove()
  }
}
```

**And** `app/assets/javascripts/controllers/auto_submit_controller.js` exists:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Auto-submit form when checkboxes change
    this.element.querySelectorAll('input[type="checkbox"]').forEach(checkbox => {
      checkbox.addEventListener('change', () => {
        this.element.requestSubmit()
      })
    })

    // Auto-submit form when date changes
    this.element.querySelector('input[type="date"]')?.addEventListener('change', () => {
      this.element.requestSubmit()
    })
  }
}
```

**And** desktop: filter panel is sticky sidebar (`sticky top-4`) in right column (30% width)
**And** mobile: filter panel shown as fixed overlay (Story 5.2)
**And** filter header has terracotta background with white text
**And** close button (×) only visible on mobile overlay (`lg:hidden`)
**And** checkboxes styled with terracotta focus ring
**And** checkboxes auto-submit form on change (Stimulus auto-submit controller)
**And** date field auto-submits on change
**And** distance field disabled with note "Géolocalisation disponible prochainement" (post-MVP FR8)
**And** "Appliquer" button full-width terracotta with hover effect
**And** "Réinitialiser" link clears all filters and reloads event list
**And** form submits via Turbo Frame (`data: { turbo_frame: "events-list" }`) - only event list reloads, not full page

---

## Story 5.2: Mobile Filter Overlay

As a mobile visitor,
I want to access filters via a collapsible button,
So that filters don't take up screen space when I'm browsing events.

**Acceptance Criteria:**

**Given** event list on mobile (<1024px width)
**When** I tap "Filtrez l'agenda" button
**Then** filter overlay slides in from right

**And** `app/views/events/index.html.erb` includes mobile filter button:

```erb
<%# Mobile filter button (hidden on desktop) %>
<button data-action="click->mobile-filters#open"
        class="lg:hidden fixed bottom-4 right-4 bg-terracotta text-white px-6 py-3 rounded-full shadow-lg z-40 flex items-center gap-2">
  <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
    <path fill-rule="evenodd" d="M3 3a1 1 0 011-1h12a1 1 0 011 1v3a1 1 0 01-.293.707L12 11.414V15a1 1 0 01-.293.707l-2 2A1 1 0 018 17v-5.586L3.293 6.707A1 1 0 013 6V3z" clip-rule="evenodd"/>
  </svg>
  Filtrez l'agenda
</button>

<%# Mobile filter overlay (hidden by default) %>
<div data-mobile-filters-target="overlay"
     class="hidden fixed inset-0 bg-black/50 z-50 lg:hidden"
     data-action="click->mobile-filters#close">
</div>

<aside data-mobile-filters-target="panel"
       class="hidden fixed top-0 right-0 h-full w-80 bg-white z-50 overflow-y-auto transform transition-transform lg:hidden filter-overlay">
  <%= render 'shared/filters' %>
</aside>
```

**And** `app/assets/javascripts/controllers/mobile_filters_controller.js` exists:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "panel"]

  open() {
    this.overlayTarget.classList.remove("hidden")
    this.panelTarget.classList.remove("hidden")
    // Prevent body scroll when overlay open
    document.body.style.overflow = 'hidden'
  }

  close() {
    this.overlayTarget.classList.add("hidden")
    this.panelTarget.classList.add("hidden")
    // Restore body scroll
    document.body.style.overflow = ''
  }
}
```

**And** floating button positioned bottom-right corner (`fixed bottom-4 right-4`)
**And** button has filter icon (SVG) + text "Filtrez l'agenda"
**And** button only visible on mobile (`lg:hidden`)
**And** tapping button opens overlay with filter panel sliding in from right
**And** overlay is semi-transparent black (`bg-black/50`)
**And** filter panel width 320px (`w-80`), full height, scrollable if content overflows
**And** tapping overlay background closes filter panel
**And** close button (×) in filter header closes panel
**And** body scroll disabled when overlay open
**And** panel has slide-in animation (`transform transition-transform`)

---

## Story 5.3: EventsController Filter Query Logic

As a system,
I want to filter events based on query parameters,
So that users see only events matching their filter criteria.

**Acceptance Criteria:**

**Given** filter form submitted with query params
**When** EventsController#index receives params
**Then** events are filtered accordingly:

```ruby
# app/controllers/events_controller.rb
def index
  @events = Event.futurs.includes(:professor)

  # Apply filters
  @events = apply_filters(@events, params)

  @events = @events.order(:date_debut).page(params[:page]).per(30)

  @cache_key = "events-index-#{cache_key_for_filters(params)}-#{Event.maximum(:updated_at)&.to_i || 0}"

  respond_to do |format|
    format.html
    format.turbo_stream
  end
end

private

def apply_filters(scope, params)
  # Date filter (FR3)
  if params[:date_debut].present?
    date = Date.parse(params[:date_debut]) rescue nil
    scope = scope.where('date_debut >= ?', date.beginning_of_day) if date
  end

  # Type filter (FR4)
  if params[:atelier] == 'true' && params[:stage] != 'true'
    scope = scope.where(type_event: :atelier)
  elsif params[:stage] == 'true' && params[:atelier] != 'true'
    scope = scope.where(type_event: :stage)
  end
  # If both checked or both unchecked, show all

  # Format filters (FR5)
  if params[:en_ligne] == 'true' && params[:en_presentiel] != 'true'
    scope = scope.where(en_ligne: true)
  elsif params[:en_presentiel] == 'true' && params[:en_ligne] != 'true'
    scope = scope.where(en_presentiel: true)
  end
  # If both checked or both unchecked, show all

  # Price filter (FR6)
  if params[:gratuit] == 'true'
    scope = scope.where(gratuit: true)
  end

  # Geographic filter (basic MVP - exact match)
  # Post-MVP: Replace with Algolia Geo Search for proximity search
  if params[:lieu].present?
    scope = scope.where('lieu ILIKE ?', "%#{params[:lieu]}%")
  end

  # Distance filter (FR8 - post-MVP with geocoding)
  # Disabled in MVP

  scope
end

def cache_key_for_filters(params)
  filter_params = params.slice(:date_debut, :atelier, :stage, :en_ligne, :en_presentiel, :gratuit, :lieu)
  Digest::MD5.hexdigest(filter_params.to_query)
end
```

**And** date filter uses `date_debut >= selected_date.beginning_of_day` to include events on selected date
**And** type filter (atelier/stage) logic:
  - Both checked → show all
  - Both unchecked → show all
  - Only atelier → show only ateliers
  - Only stage → show only stages
**And** format filter (en_ligne/en_presentiel) logic same as type filter
**And** price filter (gratuit) only active when checked
**And** lieu filter uses ILIKE for case-insensitive partial match (PostgreSQL)
**And** distance filter disabled in MVP (field present but non-functional)
**And** cache key includes filter params hash to cache filtered results separately
**And** all filters cumulative (AND logic, not OR)
**And** invalid date params gracefully ignored (rescue)

---

## Story 5.4: Search Component Block (Basic MVP, Algolia Post-MVP)

As a visitor,
I want a search input to find events by keyword,
So that I can quickly locate specific events or dance styles.

**Acceptance Criteria:**

**Given** filter sidebar
**When** I use search component
**Then** `app/views/shared/_search.html.erb` partial exists:

```erb
<div class="bg-terracotta-dark text-white rounded-lg p-6 mb-6">
  <h2 class="font-script italic text-2xl mb-4">Recherchez</h2>

  <%= form_with url: evenements_path,
                method: :get,
                data: { turbo_frame: "events-list" },
                class: "relative" do |f| %>
    <%= f.text_field :q,
                     value: params[:q],
                     placeholder: "Saisir votre recherche directement",
                     class: "w-full rounded border-0 py-3 pl-4 pr-10 focus:ring-2 focus:ring-white",
                     disabled: true %>

    <button type="submit"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400"
            disabled>
      <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
        <path fill-rule="evenodd" d="M8 4a4 4 0 100 8 4 4 0 000-8zM2 8a6 6 0 1110.89 3.476l4.817 4.817a1 1 0 01-1.414 1.414l-4.816-4.816A6 6 0 012 8z" clip-rule="evenodd"/>
      </svg>
    </button>

    <p class="text-xs mt-2 opacity-75">Recherche complète disponible prochainement (Algolia)</p>
  <% end %>
</div>
```

**And** search input disabled in MVP (`disabled: true`)
**And** placeholder text: "Saisir votre recherche directement"
**And** note below input: "Recherche complète disponible prochainement (Algolia)" (FR7 post-MVP)
**And** search icon (magnifying glass) positioned on right side of input
**And** terracotta dark background (`bg-terracotta-dark`) with white text
**And** component rendered in sidebar above filters
**And** POST-MVP: Algolia integration for full-text search (FR7)

---

## Story 5.5: Filter State Persistence in URL

As a visitor,
I want filter selections to appear in the URL,
So that I can bookmark or share filtered event lists.

**Acceptance Criteria:**

**Given** filters applied
**When** I look at browser URL
**Then** URL includes query params:

Example: `/evenements?gratuit=true&en_presentiel=true&date_debut=2026-03-25`

**And** query params mapped to filter form fields:
- `date_debut=2026-03-25` → date field pre-filled
- `atelier=true` → atelier checkbox checked
- `stage=true` → stage checkbox checked
- `en_ligne=true` → en ligne checkbox checked
- `en_presentiel=true` → en présentiel checkbox checked
- `gratuit=true` → gratuit checkbox checked
- `lieu=Paris` → lieu text field pre-filled

**And** form helper pre-fills fields from params:

```erb
<%# Example checkbox pre-checked from params %>
<%= f.check_box :gratuit,
                { checked: params[:gratuit] == 'true' },
                "true", nil %>

<%# Example date field pre-filled from params %>
<%= f.date_field :date_debut,
                 value: params[:date_debut] %>

<%# Example text field pre-filled from params %>
<%= f.text_field :lieu,
                 value: params[:lieu] %>
```

**And** URL shareable: sending URL to someone else loads same filtered view
**And** bookmarking URL saves filter state
**And** browser back/forward buttons work correctly with filter state
**And** URL updates when filters change (Turbo Frame navigation preserves query params)

---

## Epic 5 Summary

**Total Stories:** 5

**All requirements covered:**
- FR3: Filter events by date (Story 5.3)
- FR4: Filter events by type (atelier/stage) (Story 5.3)
- FR5: Filter events by format (présentiel/en ligne) (Story 5.3)
- FR6: Filter events by price (gratuit) (Story 5.3)
- FR7: Keyword search (POST-MVP, placeholder in Story 5.4)
- FR8: Geolocation search (POST-MVP, placeholder in Story 5.1)
- UX-DR15: Filter panel (desktop sticky sidebar, mobile fixed overlay) (Stories 5.1, 5.2)
- UX-DR16: Filter checkboxes in 2-column grid (Story 5.1)
- UX-DR17: Date range filter with JJ/MM/AAAA input (Story 5.1)
- UX-DR18: Geographic filter (LIEU + DISTANCE, basic MVP) (Story 5.1)
- UX-DR19: "APPLIQUER" button full-width terracotta (Story 5.1)
- UX-DR20: Search component with terracotta dark background (Story 5.4)

**Key Deliverables:**
- Filter panel component (desktop sidebar + mobile overlay)
- Mobile filter button with overlay slide-in animation
- Filters Stimulus controller for mobile interactions
- Auto-submit Stimulus controller for instant filtering
- EventsController filter query logic (cumulative AND filters)
- Search component placeholder (Algolia post-MVP)
- Filter state persistence in URL query params
- Cache key includes filter params for efficient caching
- Turbo Frame integration for partial page updates
