# Epic 8: SEO & Discoverability - Stories

Enable search engines to index all events and users to share events beautifully on social media.

**User Outcome:** Events appear in Google Search with rich snippets, site is fully indexed, and events look great when shared on Facebook/Twitter.

**FRs covered:** FR26-FR32, FR51, NFR-P1 à P6

---

## Story 8.1: SEO Metadata Concern for Controllers

As a system,
I want reusable SEO metadata generation for all pages,
So that every page has proper title, description, and canonical URL.

**Acceptance Criteria:**

**Given** controllers need SEO metadata
**When** I mix in SEO concern
**Then** `app/controllers/concerns/seo_metadata.rb` exists:

```ruby
module SeoMetadata
  extend ActiveSupport::Concern

  included do
    before_action :set_default_meta_tags
  end

  private

  def set_default_meta_tags
    set_meta_tags(
      site: '3 Graces',
      title: '3 Graces - Agenda de danse exploratoire',
      description: 'Agenda de référence des pratiques de danse exploratoires et non-performatives en France.',
      keywords: 'danse, contact improvisation, 5 rythmes, authentic movement, ateliers danse, stages danse, danse exploratoire',
      canonical: request.original_url,
      og: {
        title: :title,
        type: 'website',
        url: request.original_url,
        image: view_context.image_url('og-default.jpg'),
        site_name: '3 Graces'
      },
      twitter: {
        card: 'summary_large_image',
        site: '@3graces', # Update with real Twitter handle
        title: :title,
        description: :description,
        image: view_context.image_url('og-default.jpg')
      }
    )
  end

  def set_event_metadata(event)
    set_meta_tags(
      title: "#{event.titre} - #{l(event.date_debut, format: :long)}",
      description: event.description&.truncate(160) || "Atelier de danse avec #{event.professor.nom}",
      keywords: [event.tags, 'danse', event.lieu].flatten.join(', '),
      canonical: evenement_url(event.slug),
      og: {
        title: event.titre,
        type: 'article',
        url: evenement_url(event.slug),
        image: event.photo_url || view_context.image_url('og-default.jpg'),
        description: event.description&.truncate(200),
        site_name: '3 Graces'
      },
      twitter: {
        card: 'summary_large_image',
        title: event.titre,
        description: event.description&.truncate(160),
        image: event.photo_url || view_context.image_url('og-default.jpg')
      }
    )

    # Schema.org Event structured data (JSON-LD)
    set_meta_tags(
      structured_data: {
        '@context': 'https://schema.org',
        '@type': 'Event',
        name: event.titre,
        description: event.description,
        startDate: event.date_debut.iso8601,
        endDate: event.date_fin.iso8601,
        location: {
          '@type': 'Place',
          name: event.lieu,
          address: event.adresse_complete
        },
        organizer: {
          '@type': 'Person',
          name: event.professor.nom,
          url: event.professor.site_web
        },
        offers: {
          '@type': 'Offer',
          price: event.gratuit ? 0 : event.prix_normal,
          priceCurrency: 'EUR',
          availability: 'https://schema.org/InStock',
          url: evenement_url(event.slug)
        },
        image: event.photo_url || view_context.image_url('og-default.jpg')
      }
    )
  end
end
```

**And** `meta-tags` gem added to Gemfile:
```ruby
# Gemfile
gem 'meta-tags'
```

**And** gem installed: `bundle install`
**And** concern mixed into ApplicationController:
```ruby
class ApplicationController < ActionController::Base
  include SeoMetadata
end
```

**And** `app/views/layouts/application.html.erb` renders meta tags in head:
```erb
<head>
  <%= display_meta_tags %>
  <%# ... other head tags %>
</head>
```

**And** default meta tags set for all pages (site title, description, OG image)
**And** canonical URL always set to avoid duplicate content issues
**And** Open Graph tags for Facebook/LinkedIn sharing
**And** Twitter Card tags for Twitter sharing
**And** Schema.org Event structured data (JSON-LD) for Google rich snippets
**And** event metadata includes:
  - Unique title per event
  - Description truncated to 160 chars (Google snippet length)
  - Event photo for OG image (fallback to default)
  - Schema.org Event with startDate, endDate, location, organizer, price

---

## Story 8.2: XML Sitemap Generation

As a search engine crawler,
I want an XML sitemap listing all events and pages,
So that I can efficiently discover and index all site content.

**Acceptance Criteria:**

**Given** events and static pages exist
**When** crawler requests `/sitemap.xml`
**Then** `app/controllers/sitemaps_controller.rb` exists:

```ruby
class SitemapsController < ApplicationController
  def index
    @events = Event.futurs.order(:date_debut)
    @static_pages = [
      { loc: root_url, priority: 1.0 },
      { loc: about_url, priority: 0.8 },
      { loc: contact_url, priority: 0.7 },
      { loc: proposants_url, priority: 0.6 }
    ]

    respond_to do |format|
      format.xml { render template: 'sitemaps/index', layout: false }
    end
  end
end
```

**And** routes configured:
```ruby
# config/routes.rb
get '/sitemap.xml', to: 'sitemaps#index', defaults: { format: 'xml' }
```

**And** `app/views/sitemaps/index.xml.builder` exists:

```ruby
xml.instruct!
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  # Static pages
  @static_pages.each do |page|
    xml.url do
      xml.loc page[:loc]
      xml.lastmod Time.current.iso8601
      xml.changefreq 'weekly'
      xml.priority page[:priority]
    end
  end

  # Events
  @events.each do |event|
    xml.url do
      xml.loc evenement_url(event.slug)
      xml.lastmod event.updated_at.iso8601
      xml.changefreq 'weekly'
      xml.priority 0.9
    end
  end

  # Professor profiles (optional)
  Professor.find_each do |professor|
    xml.url do
      xml.loc professeur_url(professor)
      xml.lastmod professor.updated_at.iso8601
      xml.changefreq 'monthly'
      xml.priority 0.7
    end
  end
end
```

**And** sitemap includes:
  - Static pages (home, about, contact, proposants) with priority 1.0-0.6
  - All future events with priority 0.9
  - All professor profiles with priority 0.7
**And** `lastmod` uses event/professor `updated_at` timestamp
**And** `changefreq` set to 'weekly' for events (updated via scraping)
**And** sitemap cached for 1 hour to reduce database queries:
```ruby
# In controller
def index
  @events = Rails.cache.fetch('sitemap/events', expires_in: 1.hour) do
    Event.futurs.order(:date_debut).to_a
  end
  # ...
end
```

**And** `public/robots.txt` references sitemap:
```
User-agent: *
Allow: /

Sitemap: https://3graces.community/sitemap.xml
```

---

## Story 8.3: Semantic URLs with Slugs (Routing Configuration)

As a user,
I want event URLs to be readable and descriptive,
So that I can understand what an event is about from the URL alone.

**Acceptance Criteria:**

**Given** Events table with slug column (created in Story 1.1)
**And** Event model with slug generation callback (defined in Story 1.1)
**When** I configure routes for slug-based URLs
**Then** routes use slug parameter instead of ID:

```ruby
# config/routes.rb
resources :evenements, only: [:index, :show], param: :slug
```

**And** controller finds by slug (already configured in Story 4.1):
```ruby
# app/controllers/events_controller.rb
def show
  @event = Event.find_by!(slug: params[:slug])
end
```

**And** URL helpers work with slug:
```ruby
evenement_path(@event) # => /evenements/contact-improvisation-paris-2026-03-25
```

**And** slug format: `titre-lieu-YYYY-MM-DD`
  - Example: `contact-improvisation-paris-2026-03-25`
  - Example: `stage-5-rythmes-lyon-2026-04-12`

**And** slug uses `parameterize` to handle French accents and special characters:
  - "Danse des 5 Rythmes" → "danse-des-5-rythmes"
  - "Atelier à Paris" → "atelier-a-paris"

**NOTE:** Slug column and generation callback already defined in Epic 1, Story 1.1 (Events table migration + model callback). This story focuses on routing configuration only.

---

## Story 8.4: Performance Optimization (Images, CSS/JS, Turbo)

As a visitor,
I want pages to load quickly on mobile networks,
So that I can browse events smoothly even on slow connections.

**Acceptance Criteria:**

**Given** performance requirements (FCP < 1.5s, LCP < 2.5s)
**When** I optimize assets
**Then** the following optimizations are in place:

**Image Optimization:**
- WebP format for all images (with JPEG/PNG fallback)
- Lazy loading on all images: `loading="lazy"` attribute
- Image sizing: `width` and `height` attributes to prevent layout shift
- Avatar images optimized: 128x128 max (professor profiles), 80x80 (event cards)

**CSS/JS Minification (Propshaft):**
```ruby
# config/environments/production.rb
config.assets.compile = false
config.assets.digest = true # Fingerprinting for cache busting
```

**Turbo Navigation:**
- Already configured (Rails 8 default)
- Instant page navigation without full reload
- Turbo Drive caches pages in memory

**Fragment Caching:**
```erb
<%# app/views/events/index.html.erb %>
<% cache @cache_key do %>
  <%= render 'events_list', events: @events %>
<% end %>
```

**Cache invalidation after scraping:**
```ruby
# In EventUpdateJob after events updated
Rails.cache.delete("events-index-#{Event.maximum(:updated_at)&.to_i}")
```

**HTTP Caching Headers:**
```ruby
# config/environments/production.rb
config.public_file_server.headers = {
  'Cache-Control' => 'public, max-age=31536000', # 1 year for assets
  'Expires' => 1.year.from_now.httpdate
}
```

**Asset Fingerprinting (FR51):**
- Propshaft automatically fingerprints assets
- `application-abc123.css` prevents stale cache issues

**Lighthouse Performance Targets:**
- FCP (First Contentful Paint) < 1.5s ✅
- LCP (Largest Contentful Paint) < 2.5s ✅
- TTI (Time to Interactive) < 3s ✅

**And** images served as WebP when supported:
```erb
<%= image_tag event.photo_url,
              formats: [:webp, :jpg],
              loading: "lazy" %>
```

**And** CSS/JS minified in production (Propshaft default)
**And** Turbo Drive enabled (instant navigation)
**And** fragment caching for event list (cache key includes last update timestamp)
**And** static assets cached for 1 year (cache-busting via fingerprinting)

---

## Story 8.5: robots.txt and Meta Robots Configuration

As a search engine crawler,
I want clear crawling instructions,
So that I know which pages to index and which to skip.

**Acceptance Criteria:**

**Given** site with public and private areas
**When** I configure robots.txt
**Then** `public/robots.txt` exists:

```
User-agent: *
Allow: /

# Allow all public routes
Allow: /evenements
Allow: /professeurs

# Disallow admin area
Disallow: /admin

# Sitemap
Sitemap: https://3graces.community/sitemap.xml
```

**And** stats pages have noindex meta tag (set in controller):
```ruby
# app/controllers/professors_controller.rb
def stats
  set_meta_tags(robots: 'noindex, follow')
end
```

**And** admin pages have noindex meta tag:
```ruby
# app/controllers/admin/application_controller.rb
class Admin::ApplicationController < ApplicationController
  before_action :set_admin_meta_tags

  private

  def set_admin_meta_tags
    set_meta_tags(robots: 'noindex, nofollow')
  end
end
```

**And** all public event/professor pages have no robots restriction (indexed by default)
**And** sitemap URL included in robots.txt
**And** admin area disallowed in robots.txt (double protection with HTTP Basic Auth)

---

## Epic 8 Summary

**Total Stories:** 5

**All requirements covered:**
- FR26: Unique meta tags per page (Story 8.1)
- FR27: Schema.org Event markup (Story 8.1)
- FR28: Rich snippet display in Google (Story 8.1)
- FR29: Open Graph tags for social sharing (Story 8.1)
- FR30: XML sitemap (Story 8.2)
- FR31: robots.txt configuration (Story 8.5)
- FR32: Semantic clean URLs (Story 8.3)
- FR51: Asset fingerprinting for cache busting (Story 8.4)
- NFR-P1-P6: Performance optimization (FCP, LCP, TTI, images, minification, Turbo) (Story 8.4)

**Key Deliverables:**
- SEO Metadata concern with meta-tags gem integration
- Unique title/description/canonical URL per page
- Schema.org Event JSON-LD structured data for rich snippets
- Open Graph tags for Facebook/LinkedIn/Twitter sharing
- XML sitemap with events, professors, static pages
- Semantic slug URLs (`titre-lieu-YYYY-MM-DD`)
- Slug auto-generation with uniqueness handling
- Performance optimizations:
  - WebP images with lazy loading
  - CSS/JS minification via Propshaft
  - Asset fingerprinting for cache busting
  - Fragment caching for event list
  - Turbo Drive for instant navigation
- robots.txt with sitemap reference
- Meta robots tags for admin/stats pages (noindex)
- Lighthouse performance targets met (FCP < 1.5s, LCP < 2.5s, TTI < 3s)

**Post-MVP:**
- Dynamic sitemap for large sites (sitemap index)
- Image CDN (Cloudinary) for automatic WebP conversion
- Additional structured data (BreadcrumbList, Organization)
- AMP pages for mobile-first indexing
