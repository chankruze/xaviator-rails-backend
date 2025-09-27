Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  post   "/auth/signup",  to: "auth#signup"
  post   "/auth/signin",  to: "auth#signin"
  post   "/auth/refresh", to: "auth#refresh"
  delete "/auth/revoke",  to: "auth#revoke"

  namespace :api do
    namespace :v1 do
      resources :aviator_rounds, only: %i[index show] do
        # Betting endpoint for users
        post :bet, on: :member
      end
    end
  end
end
