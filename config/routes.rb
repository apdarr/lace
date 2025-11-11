Rails.application.routes.draw do
  # Initial OAuth request (handled by OmniAuth middleware)
  post "/auth/strava"
  # OAuth callback (handled by our sessions#create)
  get "/auth/strava/callback", to: "sessions#create"
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
  get "profile", to: "profile#show"

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
