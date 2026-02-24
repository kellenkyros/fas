Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  scope module: :identity do
    # Profile (Singular resource style)
    get   "/profile", to: "profiles#show"
    patch "/profile/change_password", to: "profiles#change_password"

    # Authentication / Session Management
    post   "/signup", to: "users#signup"
    post   "/login", to: "sessions#create"
    delete "/logout", to: "sessions#destroy"
    post   "/session/refresh", to: "sessions#refresh"

    # Magic Link Flow
    # 1. Request the link
    # post "/send_magic_login", to: "sessions#send_magic_login"
    
    post "/send_magic_login", to: "login_attempts#create"

    # 2. Desktop listens for the "Ping" (SSE)
    get "/login_attempts/:id/subscribe", to: "login_attempts#subscribe"

    # 3. Mobile clicks the link from the email
    get "/magic_login", to: "magic_links#authenticate", as: :magic_login
    
    #get  "/magic_login", to: "sessions#magic_login", as: :magic_login
  end


  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
