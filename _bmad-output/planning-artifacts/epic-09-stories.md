# Epic 9: Admin Interface - Stories

Enable administrators to manage scraping URLs, view logs, and correct event data via web interface.

**User Outcome:** Admins can add/edit scraping URLs, trigger manual scraping, view change logs, and correct parsing errors through a simple admin dashboard.

**FRs covered:** FR39-FR44, ARCH-21 à ARCH-23

---

## Story 9.1: Admin HTTP Basic Auth with Environment Credentials

As an administrator,
I want secure access to the admin interface,
So that only authorized users can manage scraping URLs and events.

**Acceptance Criteria:**

**Given** production environment with credentials
**When** I access `/admin` routes
**Then** HTTP Basic Auth prompts for credentials

**And** `.env` file contains admin credentials:
```bash
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change_me_in_production
```

**And** `.env.example` documents required variables:
```bash
# Admin credentials for HTTP Basic Auth
ADMIN_USERNAME=admin
ADMIN_PASSWORD=change_me_in_production

# Alert email for scraping failures
ALERT_EMAIL=admin@3graces.community
```

**And** `app/controllers/admin/application_controller.rb` exists:

```ruby
class Admin::ApplicationController < ActionController::Base
  http_basic_authenticate_with(
    name: ENV.fetch('ADMIN_USERNAME'),
    password: ENV.fetch('ADMIN_PASSWORD')
  )

  before_action :set_admin_meta_tags
  layout 'admin'

  private

  def set_admin_meta_tags
    set_meta_tags(robots: 'noindex, nofollow')
  end
end
```

**And** admin layout exists at `app/views/layouts/admin.html.erb`:

```erb
<!DOCTYPE html>
<html>
  <head>
    <title>Admin - 3 Graces</title>
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>
    <%= display_meta_tags %>
    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="bg-gray-100">
    <%# Admin navbar %>
    <nav class="bg-dark-bg text-white py-4 mb-8">
      <div class="container mx-auto px-4">
        <div class="flex items-center justify-between">
          <h1 class="text-xl font-bold">Admin - 3 Graces</h1>
          <div class="flex items-center gap-6">
            <%= link_to "URLs", admin_scraped_urls_path, class: "hover:text-terracotta" %>
            <%= link_to "Changements", admin_change_logs_path, class: "hover:text-terracotta" %>
            <%= link_to "Événements", admin_events_path, class: "hover:text-terracotta" %>
            <%= link_to "← Site public", root_path, class: "hover:text-terracotta" %>
          </div>
        </div>
      </div>
    </nav>

    <main class="container mx-auto px-4 pb-12">
      <%= render 'shared/flash' %>
      <%= yield %>
    </main>
  </body>
</html>
```

**And** admin routes namespaced:
```ruby
# config/routes.rb
namespace :admin do
  root to: 'scraped_urls#index'
  resources :scraped_urls do
    member do
      post :scrape_now
      get :preview
    end
  end
  resources :change_logs, only: [:index, :show]
  resources :events, only: [:index, :show, :edit, :update]
end
```

**And** browser prompts for username/password when accessing `/admin`
**And** credentials from `.env` validated (never hardcoded)
**And** `.env` in `.gitignore` (credentials never committed)
**And** README documents copying `.env.example` to `.env` before deployment
**And** admin pages have `noindex, nofollow` meta robots tag
**And** HTTPS enforced in production (Caddy + Rails `force_ssl`)

---

## Story 9.2: Admin ScrapedUrls Controller (CRUD + Actions)

As an administrator,
I want to add, edit, and manage scraping URLs,
So that I can configure which professor websites to scrape.

**Acceptance Criteria:**

**Given** admin authenticated
**When** I manage scraping URLs
**Then** `app/controllers/admin/scraped_urls_controller.rb` exists:

```ruby
class Admin::ScrapedUrlsController < Admin::ApplicationController
  before_action :find_scraped_url, only: [:show, :edit, :update, :destroy, :scrape_now, :preview]

  def index
    # Pagy syntax: @pagy, @records = pagy(scope, items: N)
    @pagy, @scraped_urls = pagy(
      ScrapedUrl.includes(:professors).order(created_at: :desc),
      items: 20
    )
  end

  def show
    @recent_change_logs = @scraped_url.change_logs.order(created_at: :desc).limit(10)
  end

  def new
    @scraped_url = ScrapedUrl.new
  end

  def create
    @scraped_url = ScrapedUrl.new(scraped_url_params)

    if @scraped_url.save
      redirect_to admin_scraped_url_path(@scraped_url), notice: "URL ajoutée avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @scraped_url.update(scraped_url_params)
      redirect_to admin_scraped_url_path(@scraped_url), notice: "URL mise à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @scraped_url.destroy
    redirect_to admin_scraped_urls_path, notice: "URL supprimée."
  end

  def scrape_now
    # Trigger immediate scraping (enqueue job)
    ScrapingJob.perform_later(@scraped_url.id)

    redirect_to admin_scraped_url_path(@scraped_url),
                notice: "Scraping lancé. Consultez les logs pour voir le résultat."
  end

  def preview
    # Dry-run: fetch + parse without DB write
    # Use ScrapingEngine.detect_scraper (public method from Story 3.4)
    # to avoid duplicating URL pattern detection logic
    scraper = ScrapingEngine.detect_scraper(@scraped_url.url)
    result = scraper.fetch(@scraped_url.url)

    if result[:error]
      @error = result[:error]
    else
      @html = result[:html]
      @parse_result = ClaudeCliIntegration.parse_and_generate(
        @scraped_url,
        result[:html],
        @scraped_url.notes_correctrices
      )
    end

    render :preview
  end

  private

  def find_scraped_url
    @scraped_url = ScrapedUrl.find(params[:id])
  end

  def scraped_url_params
    params.require(:scraped_url).permit(:url, :notes_correctrices, :statut_scraping)
  end
end
```

**And** index page lists all URLs with pagination (pagy gem, 20 per page)
**And** show page displays URL details + recent 10 change logs
**And** new/edit pages have form with fields: url, notes_correctrices, statut_scraping
**And** create/update actions validate URL format and uniqueness
**And** destroy action soft-deletes or hard-deletes URL (confirm with user)
**And** scrape_now action:
  - Enqueues ScrapingJob immediately
  - Redirects with notice
  - Does NOT wait for job completion (async)
**And** preview action:
  - Fetches HTML via appropriate scraper
  - Parses with Claude CLI
  - Displays parsed events in preview page
  - Does NOT create Event records
  - Does NOT update ScrapedUrl.derniere_version_html
  - Useful for testing before activation

---

## Story 9.3: Admin ScrapedUrls Views (Index, Show, Form, Preview)

As an administrator,
I want simple, functional views for managing scraping URLs,
So that I can perform CRUD operations without complex UI.

**Acceptance Criteria:**

**Given** admin controllers exist
**When** I render admin views
**Then** the following views exist:

**Index (`app/views/admin/scraped_urls/index.html.erb`):**

```erb
<div class="flex items-center justify-between mb-6">
  <h1 class="text-2xl font-bold">URLs à scraper</h1>
  <%= link_to "Ajouter une URL", new_admin_scraped_url_path, class: "bg-terracotta text-white px-4 py-2 rounded hover:bg-terracotta-dark" %>
</div>

<div class="bg-white rounded shadow">
  <table class="w-full">
    <thead class="bg-gray-100 border-b">
      <tr>
        <th class="text-left p-4">URL</th>
        <th class="text-left p-4">Statut</th>
        <th class="text-left p-4">Erreurs</th>
        <th class="text-left p-4">Dernière mise à jour</th>
        <th class="text-left p-4">Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @scraped_urls.each do |scraped_url| %>
        <tr class="border-b hover:bg-gray-50">
          <td class="p-4">
            <%= link_to scraped_url.url.truncate(60), admin_scraped_url_path(scraped_url), class: "text-terracotta hover:underline" %>
          </td>
          <td class="p-4">
            <span class="px-2 py-1 rounded text-sm <%= scraped_url.statut_scraping == 'actif' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800' %>">
              <%= scraped_url.statut_scraping %>
            </span>
          </td>
          <td class="p-4">
            <span class="<%= scraped_url.erreurs_consecutives >= 3 ? 'text-red-600 font-bold' : 'text-gray-600' %>">
              <%= scraped_url.erreurs_consecutives %>
            </span>
          </td>
          <td class="p-4 text-sm text-gray-600">
            <%= l(scraped_url.updated_at, format: :short) if scraped_url.updated_at %>
          </td>
          <td class="p-4">
            <%= link_to "Voir", admin_scraped_url_path(scraped_url), class: "text-blue-600 hover:underline mr-3" %>
            <%= link_to "Modifier", edit_admin_scraped_url_path(scraped_url), class: "text-blue-600 hover:underline" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<div class="mt-4">
  <%== pagy_nav(@pagy) if @pagy %>
</div>
```

**Show (`app/views/admin/scraped_urls/show.html.erb`):**

```erb
<div class="mb-6">
  <%= link_to "← Retour à la liste", admin_scraped_urls_path, class: "text-terracotta hover:underline" %>
</div>

<div class="bg-white rounded shadow p-6 mb-6">
  <div class="flex items-center justify-between mb-6">
    <h1 class="text-2xl font-bold">Détails de l'URL</h1>
    <div class="flex gap-2">
      <%= link_to "Modifier", edit_admin_scraped_url_path(@scraped_url), class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
      <%= button_to "Scraper maintenant", scrape_now_admin_scraped_url_path(@scraped_url), method: :post, class: "bg-terracotta text-white px-4 py-2 rounded hover:bg-terracotta-dark" %>
      <%= link_to "Prévisualiser", preview_admin_scraped_url_path(@scraped_url), class: "bg-gray-600 text-white px-4 py-2 rounded hover:bg-gray-700" %>
    </div>
  </div>

  <dl class="space-y-3">
    <div>
      <dt class="font-bold">URL :</dt>
      <dd><%= link_to @scraped_url.url, @scraped_url.url, target: "_blank", class: "text-blue-600 hover:underline" %></dd>
    </div>

    <div>
      <dt class="font-bold">Statut :</dt>
      <dd><%= @scraped_url.statut_scraping %></dd>
    </div>

    <div>
      <dt class="font-bold">Erreurs consécutives :</dt>
      <dd class="<%= @scraped_url.erreurs_consecutives >= 3 ? 'text-red-600 font-bold' : '' %>">
        <%= @scraped_url.erreurs_consecutives %>
      </dd>
    </div>

    <div>
      <dt class="font-bold">Notes correctrices :</dt>
      <dd class="whitespace-pre-wrap bg-gray-50 p-3 rounded"><%= @scraped_url.notes_correctrices.presence || "(aucune)" %></dd>
    </div>
  </dl>
</div>

<%# Recent change logs %>
<div class="bg-white rounded shadow p-6">
  <h2 class="text-xl font-bold mb-4">10 derniers changements détectés</h2>

  <% if @recent_change_logs.any? %>
    <div class="space-y-3">
      <% @recent_change_logs.each do |log| %>
        <div class="border-b pb-3">
          <%= link_to l(log.created_at, format: :long), admin_change_log_path(log), class: "text-terracotta hover:underline" %>
          <span class="text-sm text-gray-600 ml-2">
            (<%= log.changements_detectes['lines_added'] %> ajoutées, <%= log.changements_detectes['lines_removed'] %> supprimées)
          </span>
        </div>
      <% end %>
    </div>
  <% else %>
    <p class="text-gray-500 italic">Aucun changement détecté pour le moment.</p>
  <% end %>
</div>
```

**Form partial (`app/views/admin/scraped_urls/_form.html.erb`):**

```erb
<%= form_with model: [:admin, @scraped_url], class: "space-y-4" do |f| %>
  <% if @scraped_url.errors.any? %>
    <div class="bg-red-50 border border-red-200 rounded p-4">
      <h3 class="font-bold text-red-800 mb-2">Erreurs :</h3>
      <ul class="list-disc list-inside text-red-700">
        <% @scraped_url.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :url, "URL à scraper", class: "block font-bold mb-1" %>
    <%= f.url_field :url, required: true, class: "w-full border border-gray-300 rounded px-3 py-2", placeholder: "https://example.com/evenements" %>
  </div>

  <div>
    <%= f.label :statut_scraping, "Statut", class: "block font-bold mb-1" %>
    <%= f.select :statut_scraping, [['Actif', 'actif'], ['Inactif', 'inactif']], {}, class: "border border-gray-300 rounded px-3 py-2" %>
  </div>

  <div>
    <%= f.label :notes_correctrices, "Notes correctrices (optionnel)", class: "block font-bold mb-1" %>
    <%= f.text_area :notes_correctrices, rows: 8, class: "w-full border border-gray-300 rounded px-3 py-2 font-mono text-sm", placeholder: "Instructions pour Claude CLI (ex: ignorer les événements passés, format date spécial, etc.)" %>
    <p class="text-sm text-gray-600 mt-1">Ces notes seront lues par Claude CLI avant le parsing.</p>
  </div>

  <div class="flex gap-3">
    <%= f.submit "Enregistrer", class: "bg-terracotta text-white px-6 py-2 rounded hover:bg-terracotta-dark cursor-pointer" %>
    <%= link_to "Annuler", admin_scraped_urls_path, class: "bg-gray-300 text-gray-800 px-6 py-2 rounded hover:bg-gray-400" %>
  </div>
<% end %>
```

**Preview (`app/views/admin/scraped_urls/preview.html.erb`):**

```erb
<div class="mb-6">
  <%= link_to "← Retour", admin_scraped_url_path(@scraped_url), class: "text-terracotta hover:underline" %>
</div>

<h1 class="text-2xl font-bold mb-6">Prévisualisation (dry-run)</h1>

<% if @error %>
  <div class="bg-red-50 border border-red-200 rounded p-4 mb-6">
    <h3 class="font-bold text-red-800 mb-2">Erreur de scraping :</h3>
    <p class="text-red-700"><%= @error %></p>
  </div>
<% elsif @parse_result[:error] %>
  <div class="bg-red-50 border border-red-200 rounded p-4 mb-6">
    <h3 class="font-bold text-red-800 mb-2">Erreur de parsing :</h3>
    <p class="text-red-700"><%= @parse_result[:error] %></p>
  </div>
<% else %>
  <div class="bg-green-50 border border-green-200 rounded p-4 mb-6">
    <h3 class="font-bold text-green-800 mb-2">Parsing réussi !</h3>
    <p class="text-green-700"><%= @parse_result[:events].size %> événement(s) détecté(s)</p>
  </div>

  <div class="space-y-6">
    <% @parse_result[:events].each_with_index do |event, i| %>
      <div class="bg-white rounded shadow p-6">
        <h3 class="font-bold text-lg mb-3">Événement <%= i + 1 %></h3>
        <dl class="space-y-2 text-sm">
          <div><dt class="font-bold inline">Titre :</dt> <dd class="inline"><%= event[:titre] %></dd></div>
          <div><dt class="font-bold inline">Date début :</dt> <dd class="inline"><%= event[:date_debut] %></dd></div>
          <div><dt class="font-bold inline">Date fin :</dt> <dd class="inline"><%= event[:date_fin] %></dd></div>
          <div><dt class="font-bold inline">Lieu :</dt> <dd class="inline"><%= event[:lieu] %></dd></div>
          <div><dt class="font-bold inline">Prix :</dt> <dd class="inline"><%= event[:prix_normal] %>€<%= " (réduit: #{event[:prix_reduit]}€)" if event[:prix_reduit] %></dd></div>
          <div><dt class="font-bold inline">Type :</dt> <dd class="inline"><%= event[:type_event] %></dd></div>
          <div><dt class="font-bold inline">Tags :</dt> <dd class="inline"><%= event[:tags].join(', ') %></dd></div>
          <div><dt class="font-bold inline">Description :</dt> <dd class="inline"><%= event[:description]&.truncate(200) %></dd></div>
        </dl>
      </div>
    <% end %>
  </div>
<% end %>

<div class="mt-6 bg-blue-50 border border-blue-200 rounded p-4">
  <p class="text-blue-800">
    <strong>Note :</strong> Ceci est une prévisualisation. Aucun événement n'a été créé en base de données.
    Utilisez le bouton "Scraper maintenant" sur la page de l'URL pour lancer le scraping réel.
  </p>
</div>
```

**And** all views use Tailwind CSS utility classes (no custom CSS)
**And** tables responsive on mobile (consider horizontal scroll or card layout)
**And** forms use Rails form helpers (CSRF protection)
**And** error messages displayed above forms
**And** flash messages shown at top of layout (shared/_flash partial)

---

## Story 9.4: Admin ChangeLogsController (Read-Only)

As an administrator,
I want to view change detection logs,
So that I can audit what changed on professor websites and when.

**Acceptance Criteria:**

**Given** change logs exist from scraping
**When** I view logs
**Then** `app/controllers/admin/change_logs_controller.rb` exists:

```ruby
class Admin::ChangeLogsController < Admin::ApplicationController
  def index
    scope = ChangeLog.includes(:scraped_url).order(created_at: :desc)

    # Optional filters
    if params[:scraped_url_id].present?
      scope = scope.where(scraped_url_id: params[:scraped_url_id])
    end

    if params[:date_start].present?
      scope = scope.where('created_at >= ?', Date.parse(params[:date_start]))
    end

    # Pagy syntax
    @pagy, @change_logs = pagy(scope, items: 20)
  end

  def show
    @change_log = ChangeLog.includes(:scraped_url).find(params[:id])
  end
end
```

**And** `app/views/admin/change_logs/index.html.erb`:

```erb
<h1 class="text-2xl font-bold mb-6">Changements détectés</h1>

<%# Filters %>
<div class="bg-white rounded shadow p-4 mb-6">
  <%= form_with url: admin_change_logs_path, method: :get, class: "flex flex-wrap gap-4" do |f| %>
    <div>
      <%= f.label :scraped_url_id, "URL", class: "block text-sm mb-1" %>
      <%= f.select :scraped_url_id,
                   options_from_collection_for_select(ScrapedUrl.order(:url), :id, :url, params[:scraped_url_id]),
                   { include_blank: "Toutes" },
                   class: "border border-gray-300 rounded px-3 py-2" %>
    </div>

    <div>
      <%= f.label :date_start, "À partir du", class: "block text-sm mb-1" %>
      <%= f.date_field :date_start, value: params[:date_start], class: "border border-gray-300 rounded px-3 py-2" %>
    </div>

    <%= f.submit "Filtrer", class: "self-end bg-terracotta text-white px-4 py-2 rounded hover:bg-terracotta-dark cursor-pointer" %>
    <%= link_to "Réinitialiser", admin_change_logs_path, class: "self-end bg-gray-300 text-gray-800 px-4 py-2 rounded hover:bg-gray-400" %>
  <% end %>
</div>

<%# Change logs list %>
<div class="bg-white rounded shadow">
  <table class="w-full">
    <thead class="bg-gray-100 border-b">
      <tr>
        <th class="text-left p-4">Date</th>
        <th class="text-left p-4">URL</th>
        <th class="text-left p-4">Changements</th>
        <th class="text-left p-4">Actions</th>
      </tr>
    </thead>
    <tbody>
      <% @change_logs.each do |log| %>
        <tr class="border-b hover:bg-gray-50">
          <td class="p-4 text-sm"><%= l(log.created_at, format: :long) %></td>
          <td class="p-4">
            <%= link_to log.scraped_url.url.truncate(40), admin_scraped_url_path(log.scraped_url), class: "text-terracotta hover:underline" %>
          </td>
          <td class="p-4 text-sm text-gray-600">
            +<%= log.changements_detectes['lines_added'] %> / -<%= log.changements_detectes['lines_removed'] %>
          </td>
          <td class="p-4">
            <%= link_to "Voir diff", admin_change_log_path(log), class: "text-blue-600 hover:underline" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>
</div>

<div class="mt-4">
  <%== pagy_nav(@pagy) if @pagy %>
</div>
```

**And** `app/views/admin/change_logs/show.html.erb`:

```erb
<div class="mb-6">
  <%= link_to "← Retour à la liste", admin_change_logs_path, class: "text-terracotta hover:underline" %>
</div>

<div class="bg-white rounded shadow p-6 mb-6">
  <h1 class="text-2xl font-bold mb-4">Changement détecté</h1>

  <dl class="space-y-2 mb-6">
    <div><dt class="font-bold inline">Date :</dt> <dd class="inline"><%= l(@change_log.created_at, format: :long) %></dd></div>
    <div><dt class="font-bold inline">URL :</dt> <dd class="inline"><%= link_to @change_log.scraped_url.url, admin_scraped_url_path(@change_log.scraped_url), class: "text-terracotta hover:underline" %></dd></div>
    <div><dt class="font-bold inline">Lignes ajoutées :</dt> <dd class="inline"><%= @change_log.changements_detectes['lines_added'] %></dd></div>
    <div><dt class="font-bold inline">Lignes supprimées :</dt> <dd class="inline"><%= @change_log.changements_detectes['lines_removed'] %></dd></div>
  </dl>

  <h2 class="font-bold text-lg mb-3">Diff HTML</h2>
  <div class="bg-gray-50 p-4 rounded overflow-x-auto">
    <%== @change_log.diff_html %>
  </div>
</div>
```

**And** index page has filters: scraped_url, date range
**And** show page displays diff HTML formatted (additions in green, deletions in red)
**And** pagination with pagy gem (20 logs per page)
**And** no create/edit/destroy actions (read-only)

---

## Story 9.5: Admin EventsController (View + Correction)

As an administrator,
I want to view and manually correct events,
So that I can fix parsing errors without re-scraping.

**Acceptance Criteria:**

**Given** events created by scraping
**When** I view/edit events
**Then** `app/controllers/admin/events_controller.rb` exists:

```ruby
class Admin::EventsController < Admin::ApplicationController
  before_action :find_event, only: [:show, :edit, :update]

  def index
    scope = Event.includes(:professor, :scraped_url).order(date_debut: :desc)

    # Optional filters
    if params[:professor_id].present?
      scope = scope.where(professor_id: params[:professor_id])
    end

    if params[:scraped_url_id].present?
      scope = scope.where(scraped_url_id: params[:scraped_url_id])
    end

    # Pagy syntax
    @pagy, @events = pagy(scope, items: 20)
  end

  def show
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to admin_event_path(@event), notice: "Événement mis à jour avec succès."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(
      :titre, :description, :date_debut, :date_fin,
      :lieu, :adresse_complete, :prix_normal, :prix_reduit,
      :type_event, :gratuit, :en_ligne, :en_presentiel,
      tags: []
    )
  end
end
```

**And** edit form allows correcting:
  - titre, description
  - date_debut, date_fin (datetime fields)
  - lieu, adresse_complete
  - prix_normal, prix_reduit
  - type_event (select: atelier/stage)
  - gratuit, en_ligne, en_presentiel (checkboxes)
  - tags (text field, comma-separated)

**And** `duree_minutes` is recalculated automatically via callback (not editable)
**And** `professor_id` NOT editable (to avoid breaking associations)
**And** `scraped_url_id` NOT editable (maintains scraping provenance)
**And** index page has filters: professor, scraped_url
**And** no create action (events created only via scraping)
**And** no destroy action (prevent accidental data loss)

---

## Epic 9 Summary

**Total Stories:** 5

**All requirements covered:**
- FR39: Manual URL addition via admin (Story 9.2)
- FR40-41: Notes correctrices per URL, read by Claude CLI (Stories 9.2, 9.3)
- FR42-44: Logs display (scraping, parsing, errors) (Story 9.4)
- ARCH-21: HTTP Basic Auth for admin routes (Story 9.1)
- ARCH-22: Admin controllers (ScrapedUrls CRUD, ChangeLogs read-only, Events correction) (Stories 9.2, 9.4, 9.5)
- ARCH-23: Admin routes namespace with custom actions (scrape_now, preview) (Story 9.1)

**Key Deliverables:**
- HTTP Basic Auth with environment credentials (`.env`)
- Admin layout with navbar (minimal design, Tailwind CSS)
- Admin::ScrapedUrlsController with CRUD + scrape_now + preview actions
- Admin::ScrapedUrls views (index, show, form, preview)
- Preview dry-run: fetch + parse without DB write
- Admin::ChangeLogsController (read-only) with filters
- Admin::EventsController (view + edit for corrections)
- Pagination with pagy gem (20 items per page)
- Flash messages for user feedback
- Noindex meta robots tag for all admin pages
- Simple, functional UI (no elaborate design, focus on usability)

**Post-MVP:**
- Dashboard with stats (total URLs, active/inactive, error rate, scraping frequency)
- Batch operations (activate/deactivate multiple URLs)
- Advanced filters (date range, error count threshold)
- Logs export (CSV, JSON)
- Event bulk edit (tags, professor reassignment)
- Admin user management (multiple admin accounts with roles)
