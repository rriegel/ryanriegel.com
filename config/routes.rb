Rails.application.routes.draw do
  namespace :api do
    resources :posts, only: [:index, :show], param: :slug
    resources :categories, only: [:index, :show], param: :slug
    resources :tags, only: [:index, :show], param: :slug
  end
end
