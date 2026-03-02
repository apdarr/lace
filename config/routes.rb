Rails.application.routes.draw do
  # Initial OAuth requests (handled by OmniAuth middleware)
  post "/auth/strava"
  post "/auth/google_oauth2"
  # OAuth callbacks (handled by our sessions#create)
  get "/auth/strava/callback", to: "sessions#create"
  get "/auth/google_oauth2/callback", to: "sessions#create"
  # OAuth failure
  get "/auth/failure", to: "sessions#failure"
  root to: "plans#index" # Updated to use the correct root path syntax
  resource :session
  resources :plans do
    member do
      get :edit_workouts
      patch :update_workouts
      post :create_blank_schedule
      get :processing_status
    end
  end
  resources :activities
  resource :profile, only: [ :show, :edit, :update ], controller: "profile"

  # Strava webhook endpoints
  namespace :webhooks do
    get "strava", to: "strava#verify"
    post "strava", to: "strava#event"
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
