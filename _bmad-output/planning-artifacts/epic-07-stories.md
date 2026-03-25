# Epic 7: Professor Profiles & Stats - Stories

Enable users to discover professors and view their public engagement statistics.

**User Outcome:** Users can click on a professor to see their bio, workshops, and public stats (page views + outbound clicks to their website).

**FRs covered:** FR10, FR33-FR37, ARCH-7, ARCH-33

---

## Story 7.1: ProfessorsController with Show and Stats Actions

As a visitor,
I want to access professor profiles via RESTful URLs,
So that I can view professor information and public statistics.

**Acceptance Criteria:**

**Given** Professor model exists with events and stats counters
**When** I configure routes and controller
**Then** routes exist:

```ruby
# config/routes.rb
resources :professeurs, only: [:show], path: 'professeurs' do
  member do
    get :stats # Public stats page
    get :redirect_to_site # Intermediate redirect to track clicks
  end
end
```

**And** `app/controllers/professors_controller.rb` exists:

```ruby
class ProfessorsController < ApplicationController
  before_action :find_professor, only: [:show, :stats, :redirect_to_site]

  def show
    # Increment consultation counter (atomic SQL)
    Professor.increment_counter(:consultations_count, @professor.id)

    # Load upcoming events
    @upcoming_events = @professor.events.futurs.order(:date_debut).limit(10)

    # Set SEO metadata
    set_professor_metadata(@professor)
  end

  def stats
    # Public stats page (no authentication required)
    # Set SEO metadata
    set_stats_metadata(@professor)
  end

  def redirect_to_site
    # Increment outbound clicks counter (atomic SQL)
    Professor.increment_counter(:clics_sortants_count, @professor.id)

    # Redirect to professor's website
    redirect_to @professor.site_web, allow_other_host: true, status: :see_other
  end

  private

  def find_professor
    @professor = Professor.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to evenements_path, alert: "Professeur introuvable"
  end

  def set_professor_metadata(professor)
    set_meta_tags(
      title: "#{professor.nom} - 3 Graces",
      description: professor.bio&.truncate(160) || "Profil de #{professor.nom} - Ateliers de danse",
      og: {
        title: professor.nom,
        description: professor.bio&.truncate(160),
        image: professor.avatar_url
      }
    )
  end

  def set_stats_metadata(professor)
    set_meta_tags(
      title: "Statistiques de #{professor.nom} - 3 Graces",
      description: "Page de statistiques publiques pour #{professor.nom}",
      robots: "noindex, follow" # Don't index stats pages
    )
  end
end
```

**And** show action increments `consultations_count` atomically via `Professor.increment_counter`
**And** redirect_to_site action increments `clics_sortants_count` atomically
**And** stats action has NO authentication (public access per FR37)
**And** upcoming events eager loaded to avoid N+1 queries
**And** SEO metadata set for professor pages
**And** stats pages have `noindex` robots meta tag (don't index in search engines)
**And** invalid professor ID redirects to event list with error message

---

## Story 7.2: Professor Profile Page

As a visitor,
I want to see a professor's bio, avatar, upcoming events, and link to their website,
So that I can learn about the professor and find their workshops.

**Acceptance Criteria:**

**Given** professor with events
**When** I visit `/professeurs/:id`
**Then** `app/views/professors/show.html.erb` renders:

```erb
<div class="container mx-auto px-4 py-8 max-w-4xl">
  <%# Header with avatar and bio %>
  <div class="bg-white rounded-lg shadow-sm p-8 mb-8">
    <div class="flex flex-col md:flex-row gap-6 items-start">
      <%# Avatar %>
      <div class="flex-shrink-0">
        <% if @professor.avatar_url.present? %>
          <%= image_tag @professor.avatar_url,
                        alt: @professor.nom,
                        class: "w-32 h-32 rounded-full object-cover",
                        loading: "lazy",
                        onerror: "this.onerror=null; this.src='data:image/svg+xml,%3Csvg xmlns=\"http://www.w3.org/2000/svg\" width=\"128\" height=\"128\"%3E%3Crect fill=\"%23C2623F\" width=\"128\" height=\"128\"/%3E%3Ctext x=\"50%25\" y=\"50%25\" dominant-baseline=\"middle\" text-anchor=\"middle\" font-size=\"48\" fill=\"white\"%3E#{@professor.nom[0]}%3C/text%3E%3C/svg%3E'" %>
        <% else %>
          <%# Fallback: SVG avatar with initials %>
          <div class="w-32 h-32 rounded-full bg-terracotta flex items-center justify-center text-white text-5xl font-script">
            <%= @professor.nom[0] %>
          </div>
        <% end %>
      </div>

      <%# Bio %>
      <div class="flex-grow">
        <h1 class="text-4xl font-script italic mb-4"><%= @professor.nom %></h1>

        <div class="prose max-w-none mb-4">
          <%= simple_format(@professor.bio) %>
        </div>

        <%# Links %>
        <div class="flex flex-wrap gap-3">
          <% if @professor.site_web.present? %>
            <%= link_to redirect_to_site_professeur_path(@professor),
                        target: "_blank",
                        class: "inline-flex items-center gap-2 bg-terracotta text-white px-4 py-2 rounded hover:bg-terracotta-dark transition-colors" do %>
              <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
                <path d="M11 3a1 1 0 100 2h2.586l-6.293 6.293a1 1 0 101.414 1.414L15 6.414V9a1 1 0 102 0V4a1 1 0 00-1-1h-5z"/>
                <path d="M5 5a2 2 0 00-2 2v8a2 2 0 002 2h8a2 2 0 002-2v-3a1 1 0 10-2 0v3H5V7h3a1 1 0 000-2H5z"/>
              </svg>
              Voir le site web
            <% end %>
          <% end %>

          <%= link_to stats_professeur_path(@professor),
                      class: "inline-flex items-center gap-2 border border-terracotta text-terracotta px-4 py-2 rounded hover:bg-terracotta hover:text-white transition-colors" do %>
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
              <path d="M2 11a1 1 0 011-1h2a1 1 0 011 1v5a1 1 0 01-1 1H3a1 1 0 01-1-1v-5zM8 7a1 1 0 011-1h2a1 1 0 011 1v9a1 1 0 01-1 1H9a1 1 0 01-1-1V7zM14 4a1 1 0 011-1h2a1 1 0 011 1v12a1 1 0 01-1 1h-2a1 1 0 01-1-1V4z"/>
            </svg>
            Voir les statistiques publiques
          <% end %>
        </div>
      </div>
    </div>
  </div>

  <%# Upcoming events section %>
  <div class="bg-white rounded-lg shadow-sm p-8">
    <h2 class="text-2xl font-script italic mb-6">Prochains ateliers et stages</h2>

    <% if @upcoming_events.any? %>
      <div class="space-y-4">
        <% @upcoming_events.each do |event| %>
          <%= render 'events/event_card', event: event %>
        <% end %>
      </div>

      <% if @professor.events.futurs.count > 10 %>
        <div class="mt-6 text-center">
          <%= link_to "Voir tous les événements de #{@professor.nom}",
                      evenements_path(professor_id: @professor.id),
                      class: "text-terracotta hover:underline" %>
        </div>
      <% end %>
    <% else %>
      <p class="text-gray-500 italic">Aucun événement à venir pour le moment.</p>
    <% end %>
  </div>
</div>
```

**And** avatar displayed as 128x128 rounded circle
**And** avatar fallback: if `avatar_url` fails to load, show SVG with professor initial on terracotta background (inline SVG via `onerror` attribute)
**And** bio formatted with line breaks (`simple_format`)
**And** "Voir le site web" button links to `redirect_to_site_professeur_path` (increments `clics_sortants_count`)
**And** "Voir les statistiques publiques" button links to stats page
**And** upcoming events section shows maximum 10 future events
**And** event cards reuse `events/event_card` partial
**And** link to "Voir tous les événements" if more than 10 events
**And** empty state if no upcoming events: "Aucun événement à venir pour le moment."

---

## Story 7.3: Professor Stats Page (Public, No Auth)

As a visitor or professor,
I want to see public statistics (consultations + outbound clicks),
So that professors can track engagement without needing an account.

**Acceptance Criteria:**

**Given** professor with stats counters
**When** I visit `/professeurs/:id/stats`
**Then** `app/views/professors/stats.html.erb` renders:

```erb
<div class="container mx-auto px-4 py-8 max-w-4xl">
  <%# Header %>
  <div class="mb-8">
    <%= link_to "← Retour au profil", professeur_path(@professor), class: "text-terracotta hover:underline mb-4 inline-block" %>
    <h1 class="text-4xl font-script italic">Statistiques publiques</h1>
    <p class="text-gray-600 text-xl mt-2"><%= @professor.nom %></p>
  </div>

  <%# Stats cards grid %>
  <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
    <%# Consultations card %>
    <div class="bg-white rounded-lg shadow-sm p-8 text-center">
      <div class="text-6xl font-bold text-terracotta mb-2">
        <%= number_with_delimiter(@professor.consultations_count) %>
      </div>
      <div class="text-gray-600 text-lg">
        Consultations du profil
      </div>
      <p class="text-sm text-gray-500 mt-2">
        Nombre de fois que votre profil a été consulté
      </p>
    </div>

    <%# Outbound clicks card %>
    <div class="bg-white rounded-lg shadow-sm p-8 text-center">
      <div class="text-6xl font-bold text-terracotta mb-2">
        <%= number_with_delimiter(@professor.clics_sortants_count) %>
      </div>
      <div class="text-gray-600 text-lg">
        Clics vers votre site
      </div>
      <p class="text-sm text-gray-500 mt-2">
        Nombre de fois que les visiteurs ont cliqué sur "Voir le site web"
      </p>
    </div>
  </div>

  <%# Info notice %>
  <div class="bg-blue-50 border border-blue-200 rounded-lg p-6">
    <h3 class="font-bold text-blue-900 mb-2">À propos de ces statistiques</h3>
    <ul class="text-blue-800 text-sm space-y-1 list-disc list-inside">
      <li>Ces statistiques sont publiques et accessibles à tous</li>
      <li>Elles sont mises à jour en temps réel</li>
      <li>Vous pouvez partager ce lien pour montrer votre visibilité sur 3 Graces</li>
      <li>Aucun compte n'est requis pour consulter cette page</li>
    </ul>
  </div>

  <%# Share link section %>
  <div class="bg-white rounded-lg shadow-sm p-8 mt-6">
    <h3 class="font-bold text-lg mb-4">Partager ce lien</h3>
    <div class="flex gap-2">
      <input type="text"
             readonly
             value="<%= stats_professeur_url(@professor) %>"
             class="flex-grow px-4 py-2 border border-gray-300 rounded bg-gray-50"
             id="stats-url">
      <button onclick="navigator.clipboard.writeText(document.getElementById('stats-url').value); this.textContent='✓ Copié!'; setTimeout(() => this.textContent='Copier', 2000)"
              class="bg-terracotta text-white px-6 py-2 rounded hover:bg-terracotta-dark transition-colors">
        Copier
      </button>
    </div>
  </div>
</div>
```

**And** stats page accessible at `/professeurs/:id/stats` (public, no authentication)
**And** consultations_count displayed with thousands separator (e.g., "1 234")
**And** clics_sortants_count displayed with thousands separator
**And** stats cards in 2-column grid on desktop, 1-column on mobile
**And** info notice explains stats are public and real-time
**And** shareable URL displayed in read-only input field
**And** "Copier" button copies URL to clipboard (JavaScript)
**And** button feedback: text changes to "✓ Copié!" for 2 seconds after click
**And** back link to professor profile page
**And** page has `noindex` meta tag (set in controller)

---

## Story 7.4: Atomic Counter Updates (Race Condition Prevention)

As a system,
I want atomic SQL counter updates,
So that concurrent requests don't cause incorrect counter values.

**Acceptance Criteria:**

**Given** professor stats counters
**When** multiple concurrent requests increment counters
**Then** counters increment correctly without race conditions

**And** all counter increments use `increment_counter` class method:

```ruby
# ✅ CORRECT - Atomic SQL
Professor.increment_counter(:consultations_count, professor_id)
Professor.increment_counter(:clics_sortants_count, professor_id)

# Generates SQL:
# UPDATE professors SET consultations_count = consultations_count + 1 WHERE id = ?
```

**And** NEVER use instance increment methods:

```ruby
# ❌ INCORRECT - Race condition possible
@professor.increment!(:consultations_count)
# Reads current value → increments in Ruby → saves
# If 2 requests do this simultaneously, one increment is lost
```

**And** counter increments happen BEFORE rendering views (no async issues)
**And** counters default to 0 (migration sets `default: 0`)
**And** counters never go below 0 (database constraint or validation)

**Implementation locations:**
- `ProfessorsController#show`: `Professor.increment_counter(:consultations_count, @professor.id)`
- `ProfessorsController#redirect_to_site`: `Professor.increment_counter(:clics_sortants_count, @professor.id)`

**Test with concurrent requests:**
```ruby
# test/integration/professor_stats_test.rb
test "concurrent profile views increment consultations_count correctly" do
  professor = professors(:sophie)

  # Simulate 10 concurrent requests
  threads = 10.times.map do
    Thread.new { get professeur_path(professor) }
  end
  threads.each(&:join)

  professor.reload
  assert_equal 10, professor.consultations_count
end
```

---

## Epic 7 Summary

**Total Stories:** 4

**All requirements covered:**
- FR10: Track outbound clicks to professor websites (Story 7.1, 7.2)
- FR33: Zero manual effort from professors (automatic stat tracking) (Stories 7.1, 7.4)
- FR34: Public stats page with unique URL (Story 7.3)
- FR35: Consultation count display (Story 7.3)
- FR36: Outbound clicks count display (Story 7.3)
- FR37: Public access, no account required (Stories 7.1, 7.3)
- ARCH-7: Professor model with avatar_url, bio, site_web, counters (all stories)
- ARCH-33: Atomic SQL counters via `increment_counter` (Story 7.4)

**Key Deliverables:**
- ProfessorsController with show, stats, redirect_to_site actions
- Professor profile page with avatar, bio, upcoming events, website link
- Public stats page with consultations + outbound clicks counters
- Atomic SQL counter updates (race condition prevention)
- Avatar fallback system (external URL with SVG fallback on error)
- Shareable stats URL with copy-to-clipboard button
- SEO metadata for professor pages
- Noindex meta tag for stats pages (avoid search engine indexing)

**Post-MVP:**
- Dark mode toggle on stats page (FR38 deferred)
- Stats graphs/charts over time
- Additional metrics (event attendance, average rating)
- Private dashboard for professors (account login)
