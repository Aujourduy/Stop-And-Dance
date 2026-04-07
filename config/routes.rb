Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "pages#home"

  # Static pages
  get "/a-propos", to: "pages#about", as: :about
  get "/contact", to: "pages#contact"
  get "/proposants", to: "pages#proposants", as: :proposants  # "Publier ateliers" form
  get "/actualites", to: "pages#actualites", as: :actualites  # Stub page

  # Events (public French routes)
  resources :evenements, only: [ :index, :show ], path: "evenements", controller: "events"

  # Newsletter subscriptions
  resources :newsletters, only: [ :create ]

  # Professors (public French routes)
  resources :professeurs, only: [ :show ], path: "professeurs", controller: "professors" do
    member do
      get :stats # Public stats page
      get :redirect_to_site # Intermediate redirect to track clicks
    end
  end

  # Sitemap
  get "/sitemap.xml", to: "sitemaps#index", defaults: { format: "xml" }

  # Admin namespace
  namespace :admin do
    root to: "scraped_urls#index"
    resources :scraped_urls do
      member do
        post :scrape_now
        post :crawl_site
        post :fetch_with_httparty
        post :fetch_with_playwright
        post :generate_markdown
        get :preview
        get :raw_html
      end
    end
    resources :site_crawls, only: [ :index, :show ]
    resources :change_logs, only: [ :index, :show ]
    resources :events, only: [ :index, :show, :edit, :update ]
    resources :professors, only: [ :index, :edit, :update ] do
      member do
        post :mark_reviewed
      end
    end
    resource :settings, only: [ :edit, :update ]
  end

  # Tailwind test page (temporary - for validation only)
  get "tailwind_test" => "pages#tailwind_test" if Rails.env.development?
end
