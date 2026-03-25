# Epic 4: Event Discovery & Browsing - Stories

Enable users to browse all dance events chronologically and see full event details.

**User Outcome:** Users see the complete agenda of scraped dance events, browse chronologically with infinite scroll, and click any event to see detailed information in a modal.

**FRs covered:** FR1, FR2, FR9, UX-DR9 à UX-DR14, ARCH-37

---

## Story 4.1: EventsController with Index and Show Actions

As a visitor,
I want to access event routes via RESTful URLs,
So that I can view the event list and individual event details.

**Acceptance Criteria:**

**Given** Event model exists with seeded data
**When** I configure routes and controller
**Then** `config/routes.rb` includes:

```ruby
Rails.application.routes.draw do
  # Public French routes
  resources :evenements, only: [:index, :show], path: 'evenements' do
    # Future: filters will use query params, not nested routes
  end

  # NOTE: root route defined in Story 2.3 as root 'pages#home' (homepage with hero)
  # No redirect to /evenements - homepage is the landing page with CTAs
end
```

**And** `app/controllers/events_controller.rb` exists:

```ruby
class EventsController < ApplicationController
  def index
    # Pagy syntax: @pagy, @records = pagy(scope, items: N)
    @pagy, @events = pagy(
      Event.futurs.includes(:professor).order(:date_debut),
      items: 30
    )

    # Fragment cache key includes last updated event timestamp
    @cache_key = "events-index-#{Event.maximum(:updated_at)&.to_i || 0}"

    respond_to do |format|
      format.html # Render full page
      format.turbo_stream # Render partial for infinite scroll
    end
  end

  def show
    @event = Event.includes(:professor).find_by(slug: params[:id])

    unless @event
      redirect_to evenements_path, alert: "Événement introuvable"
      return
    end

    # Increment professor consultation counter (atomic SQL)
    Professor.increment_counter(:consultations_count, @event.professor_id)

    # Set SEO metadata (concern mixed in ApplicationController)
    # set_event_metadata defined in Epic 8 (SeoMetadata concern)
    set_event_metadata(@event)
  end
end
```

**And** `pagy` gem installed in Gemfile
**And** Pagy configured in `config/initializers/pagy.rb`:
```ruby
require 'pagy/extras/overflow'
Pagy::DEFAULT[:items] = 30
Pagy::DEFAULT[:overflow] = :last_page
```

**And** `Event.futurs` scope returns only future events (`date_debut >= Time.current`)
**And** events ordered chronologically by `date_debut`
**And** professor data eager loaded via `includes(:professor)` to avoid N+1 queries
**And** show action finds event by slug (SEO-friendly URL)
**And** show action increments `consultations_count` atomically via `increment_counter`
**And** fragment cache key based on `Event.maximum(:updated_at)` to invalidate when events change
**And** Turbo Stream format responds with partial for infinite scroll (Story 4.5)

---

## Story 4.2: Event List View with Date Separators

As a visitor,
I want to see events grouped by date with visual separators,
So that I can easily scan the agenda chronologically.

**Acceptance Criteria:**

**Given** events ordered by date_debut
**When** I render the event index
**Then** `app/views/events/index.html.erb` exists:

```erb
<div class="container mx-auto px-4 py-8">
  <div class="grid grid-cols-1 lg:grid-cols-[1fr_350px] gap-8">
    <%# Main column: Event list (70% on desktop) %>
    <div>
      <h1 class="text-3xl font-script italic mb-8">Agenda des Ateliers</h1>

      <%= turbo_frame_tag "events-list", data: { controller: "infinite-scroll" } do %>
        <%= render 'events_list', events: @events %>

        <%# Infinite scroll trigger %>
        <% if @events.next_page %>
          <%= turbo_frame_tag "page-#{@events.next_page}",
                              src: evenements_path(page: @events.next_page, format: :turbo_stream),
                              loading: :lazy do %>
            <div class="text-center py-8">
              <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-terracotta"></div>
            </div>
          <% end %>
        <% end %>
      <% end %>
    </div>

    <%# Right sidebar: Filters (30% on desktop, hidden on mobile) %>
    <aside class="hidden lg:block">
      <%= render 'shared/filters' %>
      <%= render 'shared/newsletter_signup' %>
    </aside>
  </div>
</div>
```

**And** `app/views/events/_events_list.html.erb` partial:

```erb
<% current_date = nil %>

<% events.each do |event| %>
  <%# Date separator if new day %>
  <% event_date = event.date_debut.to_date %>
  <% if current_date != event_date %>
    <% current_date = event_date %>
    <%= render 'date_separator', date: event_date %>
  <% end %>

  <%# Event card %>
  <%= render 'event_card', event: event %>
<% end %>
```

**And** `app/views/events/_date_separator.html.erb`:

```erb
<%# locals: date %>
<div class="flex items-center gap-4 my-6 first:mt-0">
  <hr class="flex-grow border-gray-300">
  <time datetime="<%= date.iso8601 %>" class="text-gray-600 italic text-lg whitespace-nowrap">
    <%= l(date, format: :long) %>
  </time>
  <hr class="flex-grow border-gray-300">
</div>
```

**And** French locale configured in `config/locales/fr.yml`:
```yaml
fr:
  date:
    formats:
      long: "%A %-d %B %Y" # "Samedi 25 mars 2026"
```

**And** two-column layout: 70% event list (left), 30% sidebar (right) on desktop (lg breakpoint)
**And** sidebar hidden on mobile (`hidden lg:block`)
**And** date separators use italic gray text with horizontal lines
**And** date separators only shown when date changes (grouped by day)
**And** infinite scroll trigger appears at bottom when `@events.next_page` exists
**And** loading spinner shown while next page loads (Turbo Frame lazy loading)

---

## Story 4.3: Event Card Component

As a visitor,
I want to see event cards with photo, time, title, tags, presenter, location, and price,
So that I can quickly decide which events interest me.

**Acceptance Criteria:**

**Given** event data with all fields
**When** I render event card
**Then** `app/views/events/_event_card.html.erb` exists:

```erb
<%# locals: event %>
<%= link_to evenement_path(event.slug),
            class: "block bg-white rounded-lg shadow-sm hover:shadow-md transition-shadow p-4 mb-4",
            data: { turbo_frame: "event_modal" } do %>

  <div class="flex gap-4">
    <%# Event photo (80x80 square) %>
    <div class="flex-shrink-0">
      <% if event.photo_url.present? %>
        <%= image_tag event.photo_url,
                      alt: event.titre,
                      class: "w-20 h-20 object-cover rounded",
                      loading: "lazy" %>
      <% else %>
        <%# Placeholder if no photo %>
        <div class="w-20 h-20 bg-terracotta-light rounded flex items-center justify-center text-white text-2xl">
          <%= event.professor.nom[0] %>
        </div>
      <% end %>
    </div>

    <%# Event details %>
    <div class="flex-grow min-w-0">
      <%# Time in terracotta bold %>
      <div class="text-terracotta font-bold text-lg mb-1">
        <%= l(event.date_debut, format: :time_only) %>
      </div>

      <%# Tags %>
      <div class="flex flex-wrap gap-2 mb-2">
        <%= render 'shared/tag', text: event.type_event_humanized, variant: event.type_event %>
        <% if event.gratuit %>
          <%= render 'shared/tag', text: 'Gratuit', variant: 'gratuit' %>
        <% end %>
        <% if event.en_ligne %>
          <%= render 'shared/tag', text: 'En ligne', variant: 'en_ligne' %>
        <% end %>
        <% if event.en_presentiel %>
          <%= render 'shared/tag', text: 'En présentiel', variant: 'en_presentiel' %>
        <% end %>
      </div>

      <%# Title %>
      <h3 class="font-bold text-lg mb-1 truncate"><%= event.titre %></h3>

      <%# Presenter %>
      <p class="text-gray-600 text-sm mb-1">
        Animé par <%= event.professor.nom %>
      </p>

      <%# Location %>
      <p class="text-gray-600 text-sm flex items-center gap-1 mb-1">
        <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M5.05 4.05a7 7 0 119.9 9.9L10 18.9l-4.95-4.95a7 7 0 010-9.9zM10 11a2 2 0 100-4 2 2 0 000 4z" clip-rule="evenodd"/>
        </svg>
        <%= event.lieu %>
      </p>

      <%# Price %>
      <p class="text-gray-900 font-medium">
        <% if event.gratuit %>
          <span class="text-green-600">Gratuit</span>
        <% elsif event.prix_reduit.present? %>
          <%= number_to_currency(event.prix_normal, unit: '€', format: '%n%u') %>
          <span class="text-sm text-gray-600">(réduit: <%= number_to_currency(event.prix_reduit, unit: '€', format: '%n%u') %>)</span>
        <% else %>
          <%= number_to_currency(event.prix_normal, unit: '€', format: '%n%u') %>
        <% end %>
      </p>
    </div>
  </div>
<% end %>
```

**And** Event model has helper method:
```ruby
def type_event_humanized
  self.class.human_enum_name(:type_event, type_event)
end
```

**And** French time format configured in `config/locales/fr.yml`:
```yaml
fr:
  time:
    formats:
      time_only: "%Hh%M" # "19h30"
```

**And** tag component reused from Epic 2 (Story 2.2)
**And** event photo 80x80 square with rounded corners
**And** photo lazy loaded (`loading="lazy"`)
**And** placeholder shown if no photo (professor initial on terracotta background)
**And** card has hover effect (`hover:shadow-md`)
**And** card is clickable link to event detail (Turbo Frame modal, Story 4.4)
**And** location icon is inline SVG (no external image dependency)
**And** price formatting: "25€" or "25€ (réduit: 15€)" or "Gratuit"
**And** title truncated with ellipsis if too long (`truncate` class)

---

## Story 4.4: Event Detail Modal (Turbo Frame)

As a visitor,
I want to click an event card to see full details in a modal,
So that I can read the complete description without leaving the event list.

**Acceptance Criteria:**

**Given** event card clicked
**When** Turbo Frame loads event detail
**Then** `app/views/events/show.html.erb` exists:

```erb
<%= turbo_frame_tag "event_modal" do %>
  <%# Modal overlay %>
  <div class="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4"
       data-controller="modal"
       data-action="click->modal#close">

    <%# Modal panel %>
    <div class="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto"
         data-modal-target="panel"
         data-action="click->modal#stopPropagation">

      <%# Close button %>
      <%= link_to evenements_path,
                  class: "absolute top-4 right-4 text-gray-500 hover:text-gray-700 text-3xl",
                  data: { turbo_frame: "_top" } do %>
        &times;
      <% end %>

      <%# Content %>
      <div class="p-6">
        <%# Tags row %>
        <div class="flex flex-wrap gap-2 mb-4">
          <%= render 'shared/tag', text: @event.type_event_humanized, variant: @event.type_event %>
          <% if @event.gratuit %>
            <%= render 'shared/tag', text: 'Gratuit', variant: 'gratuit' %>
          <% end %>
          <% if @event.en_ligne %>
            <%= render 'shared/tag', text: 'En ligne', variant: 'en_ligne' %>
          <% end %>
          <% if @event.en_presentiel %>
            <%= render 'shared/tag', text: 'En présentiel', variant: 'en_presentiel' %>
          <% end %>
        </div>

        <%# Photo carousel (if multiple photos in future) %>
        <% if @event.photo_url.present? %>
          <div class="mb-4">
            <%= image_tag @event.photo_url, alt: @event.titre, class: "w-full h-64 object-cover rounded" %>
          </div>
        <% end %>

        <%# Title %>
        <h2 class="font-script italic text-3xl mb-4"><%= @event.titre %></h2>

        <%# Info block %>
        <div class="space-y-3 mb-6">
          <div>
            <span class="font-medium">Animé par :</span>
            <%= link_to @event.professor.nom, professeur_path(@event.professor), class: "text-terracotta hover:underline" %>
          </div>

          <div>
            <span class="font-medium">Début :</span>
            <%= l(@event.date_debut, format: :long) %>
          </div>

          <div>
            <span class="font-medium">Fin :</span>
            <%= l(@event.date_fin, format: :long) %>
          </div>

          <div>
            <span class="font-medium">Durée :</span>
            <%= @event.duree_minutes %> minutes
          </div>

          <div>
            <span class="font-medium">Lieu :</span>
            <%= @event.lieu %><br>
            <span class="text-sm text-gray-600"><%= @event.adresse_complete %></span>
          </div>

          <div>
            <span class="font-medium">Tarif :</span>
            <% if @event.gratuit %>
              <span class="text-green-600 font-medium">Gratuit</span>
            <% elsif @event.prix_reduit.present? %>
              <%= number_to_currency(@event.prix_normal, unit: '€', format: '%n%u') %>
              (réduit: <%= number_to_currency(@event.prix_reduit, unit: '€', format: '%n%u') %>)
            <% else %>
              <%= number_to_currency(@event.prix_normal, unit: '€', format: '%n%u') %>
            <% end %>
          </div>

          <% if @event.professor.site_web.present? %>
            <div>
              <%= link_to "Voir le site du prof →",
                          redirect_to_site_professeur_path(@event.professor),
                          target: "_blank",
                          class: "inline-block bg-terracotta text-white px-4 py-2 rounded hover:bg-terracotta-dark transition-colors" %>
            </div>
          <% end %>
        </div>

        <%# Description section %>
        <div class="border-t pt-4">
          <h3 class="text-terracotta font-bold text-xl mb-3">Description</h3>
          <div class="prose max-w-none">
            <%= simple_format(@event.description) %>
          </div>
        </div>

        <%# Tags list if any %>
        <% if @event.tags.present? %>
          <div class="border-t pt-4 mt-4">
            <h3 class="text-terracotta font-bold text-xl mb-3">Pratiques</h3>
            <div class="flex flex-wrap gap-2">
              <% @event.tags.each do |tag| %>
                <%= render 'shared/tag', text: tag, variant: 'default' %>
              <% end %>
            </div>
          </div>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

**And** `app/assets/javascripts/controllers/modal_controller.js` exists:

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  close(event) {
    // Close modal when clicking overlay (not panel)
    if (event.target === event.currentTarget) {
      window.history.back() // Or: Turbo.visit(this.element.dataset.returnUrl)
    }
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

  connect() {
    // Prevent body scroll when modal open
    document.body.style.overflow = 'hidden'
  }

  disconnect() {
    // Restore body scroll when modal closes
    document.body.style.overflow = ''
  }
}
```

**And** modal overlay covers entire viewport with semi-transparent black (`bg-black/50`)
**And** modal panel max width 2xl, max height 90vh, scrollable if content overflows
**And** close button (×) positioned top-right
**And** clicking overlay closes modal (Turbo Frame navigation back)
**And** clicking panel does NOT close modal (`stopPropagation`)
**And** body scroll disabled when modal open (via Stimulus controller)
**And** "Voir le site du prof" button redirects to professor site and increments `clics_sortants_count` (Story 7.2)
**And** datetime formatted in French: "Samedi 25 mars 2026, 19h30" (locale configured)
**And** description formatted with line breaks (`simple_format`)
**And** SEO metadata set for event page (Schema.org Event, handled in Epic 8)

---

## Story 4.5: Infinite Scroll with Turbo Frames

As a visitor,
I want events to load automatically as I scroll down,
So that I can browse many events without clicking pagination links.

**Acceptance Criteria:**

**Given** event list with 30 events per batch
**When** I scroll near the bottom
**Then** Turbo Frame lazy loads next batch automatically

**And** `app/views/events/index.turbo_stream.erb` exists:

```erb
<%= turbo_stream.append "events-list" do %>
  <%= render 'events_list', events: @events %>

  <%# Next page trigger %>
  <% if @events.next_page %>
    <%= turbo_frame_tag "page-#{@events.next_page}",
                        src: evenements_path(page: @events.next_page, format: :turbo_stream),
                        loading: :lazy do %>
      <div class="text-center py-8">
        <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-terracotta"></div>
      </div>
    <% end %>
  <% end %>
<% end %>
```

**And** EventsController responds to both `html` and `turbo_stream` formats:
```ruby
respond_to do |format|
  format.html # Full page render
  format.turbo_stream # Append events to list
end
```

**And** pagy gem configured to return 30 events per page
**And** Turbo Frame with `loading: :lazy` triggers request when scrolled into view
**And** loading spinner shown while fetching next batch
**And** when no more events (`@events.next_page` is nil), no trigger frame rendered
**And** infinite scroll works on both desktop and mobile
**And** browser back button works correctly (Turbo handles history)
**And** URL does NOT change when scrolling (no `/evenements?page=2` in URL bar for UX)

---

## Epic 4 Summary

**Total Stories:** 5

**All requirements covered:**
- FR1: Chronological event agenda display (Stories 4.1, 4.2)
- FR2: Event cards with time, tags, title, presenter, location, price (Story 4.3)
- FR9: Event detail modal with full information (Story 4.4)
- UX-DR9: Two-column layout (70% events, 30% sidebar on desktop) (Story 4.2)
- UX-DR10: Mobile full-width layout, collapsible filters (Story 4.2)
- UX-DR11: Date separator component (Story 4.2)
- UX-DR12: Event card flex layout (80x80 photo, time, tags, title, location, price) (Story 4.3)
- UX-DR13: Event detail modal with carousel, tags, presenter info (Story 4.4)
- UX-DR14: Description section scrollable (Story 4.4)
- ARCH-37: Infinite scroll with Turbo Frames, 30 events/batch, pagy gem (Story 4.5)

**Key Deliverables:**
- EventsController with index/show actions
- Event list view with date separators
- Event card component (reusable partial)
- Event detail modal (Turbo Frame)
- Infinite scroll with Turbo Frames lazy loading
- Pagy gem integration for server-side pagination
- Modal Stimulus controller for UX (body scroll lock, overlay close)
- French locale configuration for dates/times
- SEO-friendly slug URLs (`/evenements/contact-improvisation-paris-2026-03-25`)
