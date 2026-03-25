# Epic 6: Newsletter Subscription - Stories

Enable users to subscribe to email updates about new events.

**User Outcome:** Users can sign up for the newsletter from the sidebar or footer and receive event updates.

**FRs covered:** FR11, FR12, NFR-S2, ARCH-6 (Newsletter model), UX-DR21

---

## Story 6.1: Newsletter Model and Validations

As a system,
I want to store newsletter subscriptions with RGPD consent tracking,
So that I have a compliant email list for future newsletters.

**Acceptance Criteria:**

**Given** Newsletter table and migration already created in Story 1.1
**When** I add Newsletter model validations
**Then** Newsletter model exists:

```ruby
# app/models/newsletter.rb
class Newsletter < ApplicationRecord
  # Validations
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "n'est pas valide" }

  # Callbacks
  before_create :set_consent_timestamp

  # Scopes
  scope :actifs, -> { where(actif: true) }
  scope :recent, -> { order(created_at: :desc) }

  private

  def set_consent_timestamp
    self.consenti_at ||= Time.current
  end
end
```

**And** email column is unique (case-insensitive) - migration from Story 1.1
**And** email validated with URI::MailTo::EMAIL_REGEXP
**And** `consenti_at` timestamp automatically set on creation (RGPD consent tracking)
**And** `actif` boolean allows soft-delete (unsubscribe without deleting record)
**And** scopes: `actifs` (only active subscriptions), `recent` (newest first)

**NOTE:** Newsletter migration already exists from Epic 1, Story 1.1. This story adds model validations and callbacks only.

---

## Story 6.2: NewslettersController with Create Action

As a user,
I want to submit my email address to subscribe to the newsletter,
So that I receive updates about new dance events.

**Acceptance Criteria:**

**Given** newsletter signup form
**When** I submit my email
**Then** NewslettersController processes subscription:

```ruby
# app/controllers/newsletters_controller.rb
class NewslettersController < ApplicationController
  def create
    @newsletter = Newsletter.new(newsletter_params)

    if @newsletter.save
      redirect_to evenements_path, notice: "Merci ! Vous êtes inscrit(e) à notre newsletter."
    else
      # Handle error (email already exists or invalid)
      if @newsletter.errors[:email].include?("a déjà été pris(e)")
        redirect_to evenements_path, notice: "Cette adresse email est déjà inscrite à notre newsletter."
      else
        redirect_to evenements_path, alert: "Erreur : #{@newsletter.errors.full_messages.join(', ')}"
      end
    end
  end

  private

  def newsletter_params
    params.require(:newsletter).permit(:email)
  end
end
```

**And** routes configured:

```ruby
# config/routes.rb
resources :newsletters, only: [:create]
```

**And** successful subscription:
  - Creates Newsletter record
  - Sets `consenti_at` to current time
  - Sets `actif` to true (default)
  - Redirects with success flash message: "Merci ! Vous êtes inscrit(e) à notre newsletter."

**And** duplicate email:
  - Validation fails (email uniqueness)
  - Redirects with notice (not error): "Cette adresse email est déjà inscrite à notre newsletter."
  - Does NOT show error to user (UX: avoid revealing if email exists in system)

**And** invalid email:
  - Validation fails (format)
  - Redirects with alert: "Erreur : Email n'est pas valide"

**And** no newsletter record created if validation fails
**And** RGPD compliance: `consenti_at` timestamp proves user consent

---

## Story 6.3: Newsletter Signup Component (Sidebar & Footer)

As a visitor,
I want to see the newsletter signup form in the sidebar and footer,
So that I can subscribe from any page.

**Acceptance Criteria:**

**Given** application layout
**When** I view pages
**Then** `app/views/shared/_newsletter_signup.html.erb` partial exists:

```erb
<div class="bg-terracotta text-white rounded-lg p-6">
  <h2 class="font-script italic text-2xl mb-4">S'inscrire à la newsletter</h2>

  <%= form_with model: Newsletter.new,
                url: newsletters_path,
                method: :post,
                class: "space-y-3" do |f| %>

    <%= f.label :email, "Votre email", class: "block text-sm mb-1" %>
    <%= f.email_field :email,
                      placeholder: "votre@email.com",
                      required: true,
                      class: "w-full rounded border-0 py-2 px-3 text-gray-900 focus:ring-2 focus:ring-white" %>

    <%= f.submit "Souscrire",
                 class: "w-full bg-white text-terracotta font-medium py-2 rounded hover:bg-gray-100 transition-colors cursor-pointer" %>

    <p class="text-xs opacity-75">
      En vous inscrivant, vous acceptez de recevoir nos actualités par email.
      Vous pouvez vous désinscrire à tout moment.
    </p>
  <% end %>
</div>
```

**And** component rendered in sidebar (desktop):

```erb
<%# app/views/events/index.html.erb %>
<aside class="hidden lg:block">
  <%= render 'shared/search' %>
  <%= render 'shared/filters' %>
  <%= render 'shared/newsletter_signup' %> <%# ← Newsletter below filters %>
</aside>
```

**And** component rendered in footer (all pages):

```erb
<%# app/views/layouts/application.html.erb %>
<body>
  <%= render 'shared/navbar' %>
  <%= render 'shared/mobile_drawer' %>

  <main>
    <%= yield %>
  </main>

  <footer class="bg-dark-bg text-white py-12 mt-12">
    <div class="container mx-auto px-4">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
        <%# Newsletter in footer %>
        <div>
          <%= render 'shared/newsletter_signup' %>
        </div>

        <%# Other footer content (links, etc.) %>
        <div>
          <h3 class="font-script italic text-xl mb-4">Navigation</h3>
          <ul class="space-y-2">
            <li><%= link_to "Agenda", evenements_path, class: "hover:text-terracotta transition-colors" %></li>
            <li><%= link_to "À propos", about_path, class: "hover:text-terracotta transition-colors" %></li>
            <li><%= link_to "Contact", contact_path, class: "hover:text-terracotta transition-colors" %></li>
          </ul>
        </div>

        <div>
          <h3 class="font-script italic text-xl mb-4">Légal</h3>
          <ul class="space-y-2">
            <li><a href="#" class="hover:text-terracotta transition-colors">Mentions légales</a></li>
            <li><a href="#" class="hover:text-terracotta transition-colors">Politique de confidentialité</a></li>
          </ul>
        </div>
      </div>
    </div>
  </footer>
</body>
```

**And** terracotta background with white text
**And** script font for heading "S'inscrire à la newsletter"
**And** email input required (HTML5 validation)
**And** "Souscrire" button white background with terracotta text
**And** RGPD notice below button: "En vous inscrivant, vous acceptez de recevoir nos actualités par email. Vous pouvez vous désinscrire à tout moment."
**And** component responsive: full width in sidebar/footer
**And** component appears in sidebar (desktop events page) AND footer (all pages)

---

## Story 6.4: Flash Messages for Subscription Feedback

As a user,
I want to see confirmation or error messages after subscribing,
So that I know if my subscription was successful.

**Acceptance Criteria:**

**Given** newsletter form submitted
**When** subscription succeeds or fails
**Then** flash messages are displayed

**And** `app/views/layouts/application.html.erb` includes flash partial:

```erb
<main>
  <%= render 'shared/flash' %>
  <%= yield %>
</main>
```

**And** `app/views/shared/_flash.html.erb` exists:

```erb
<% if flash.any? %>
  <div class="container mx-auto px-4 py-4">
    <% flash.each do |type, message| %>
      <div class="<%= flash_class(type) %> rounded-lg p-4 mb-4 flex items-center justify-between">
        <span><%= message %></span>
        <button onclick="this.parentElement.remove()" class="text-xl ml-4">&times;</button>
      </div>
    <% end %>
  </div>
<% end %>
```

**And** `app/helpers/application_helper.rb` includes flash helper:

```ruby
module ApplicationHelper
  def flash_class(type)
    case type.to_sym
    when :notice
      "bg-green-100 text-green-800 border border-green-200"
    when :alert
      "bg-red-100 text-red-800 border border-red-200"
    when :error
      "bg-red-100 text-red-800 border border-red-200"
    else
      "bg-blue-100 text-blue-800 border border-blue-200"
    end
  end
end
```

**And** flash messages appear at top of main content area
**And** success message (notice): green background, green text
**And** error message (alert): red background, red text
**And** close button (×) dismisses flash message
**And** flash messages auto-cleared after redirect (Rails default)

**Flash message examples:**
- Success: "Merci ! Vous êtes inscrit(e) à notre newsletter."
- Already subscribed: "Cette adresse email est déjà inscrite à notre newsletter." (notice, not alert)
- Invalid email: "Erreur : Email n'est pas valide"

---

## Epic 6 Summary

**Total Stories:** 4

**All requirements covered:**
- FR11: Email newsletter signup form (Stories 6.2, 6.3)
- FR12: Newsletter subscription capability (Stories 6.1, 6.2)
- NFR-S2: User email protection (validation, uniqueness, RGPD consent tracking) (Story 6.1)
- ARCH-6: Newsletter model with email, consenti_at, actif (Story 6.1)
- UX-DR21: Newsletter signup component with terracotta background (Story 6.3)

**Key Deliverables:**
- Newsletter model with RGPD consent tracking (`consenti_at`)
- NewslettersController with create action
- Newsletter signup component (reusable partial)
- Component rendered in sidebar (desktop events page) and footer (all pages)
- Flash messages for subscription feedback (success/error)
- Email validation (presence, format, uniqueness)
- Soft-delete support via `actif` boolean (unsubscribe without data loss)
- French error messages and user-friendly feedback

**Post-MVP:**
- Actual newsletter sending (Action Mailer + scheduled job)
- Unsubscribe link in emails
- Admin interface to manage subscriptions and send newsletters
- Email service integration (SendGrid, Mailgun, etc.)
