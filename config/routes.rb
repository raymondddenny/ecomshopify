Rails.application.routes.draw do
  get "checkout/new"
  get "checkout/create"
  resources :users, only: [:new, :create]
  get 'signup', to: 'users#new', as: :signup

  resources :sessions, only: [:new, :create, :destroy]
  get 'login', to: 'sessions#new', as: :login
  post 'login', to: 'sessions#create'
  delete 'logout', to: 'sessions#destroy', as: :logout
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "products#index"

  resources :products, only: [:index, :show]

  post 'cart/add', to: 'cart#add', as: :cart_add
  post 'cart/buy_now', to: 'cart#buy_now', as: :buy_now

  get 'cart', to: 'cart#show', as: :cart
  patch 'cart/update', to: 'cart#update', as: :cart_update
  delete 'cart/remove', to: 'cart#remove', as: :cart_remove
  delete 'cart/clear', to: 'cart#clear', as: :cart_clear

  # Checkout routes
  match 'checkout', to: 'cart#checkout', via: [:get, :post], as: :checkout
end
