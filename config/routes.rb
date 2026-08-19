Rails.application.routes.draw do
  namespace :api do
    # Authentication endpoints
    post "login", to: "sessions#create"
    post "register", to: "registrations#create"
    delete "logout", to: "sessions#destroy"

    # Resource endpoints
    resources :posts, only: [ :index, :show, :create, :update, :destroy ], param: :slug
    resources :categories, only: [ :index, :show, :create, :update, :destroy ], param: :slug
    resources :tags, only: [ :index, :show, :create, :update, :destroy ], param: :slug
  end
end
