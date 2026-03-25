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

  # Tailwind test page (temporary - for validation only)
  get "tailwind_test" => "pages#tailwind_test" if Rails.env.development?
end
