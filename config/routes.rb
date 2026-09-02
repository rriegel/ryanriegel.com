Rails.application.routes.draw do
  # ActiveStorage routes must be mounted explicitly in API-only mode
  scope :rails do
    scope :active_storage do
      get "representations/:variation_key/:encoded_key/:filename",
        to: "active_storage/representations/redirect#show",
        as: :rails_active_storage_representation
      get "blobs/redirect/:signed_id/*filename",
        to: "active_storage/blobs/redirect#show",
        as: :rails_active_storage_blob
      get "disk/:encoded_key/*filename",
        to: "active_storage/disk#show",
        as: :rails_active_storage_disk
    end
  end

  namespace :api do
    namespace :v1 do
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
end
