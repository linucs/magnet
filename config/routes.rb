Rails.application.routes.draw do
  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  unless Figaro.env.disable_uploads.to_b
    mount DAV4Rack::Handler.new(
      root: File.join(Rails.root, 'public', 'system'),
      root_uri_path: '/files',
      resource_class: UserFileResource
    ), at: '/files'
  end

  concern :collectable do
    resources :boards, only: [:index, :show] do
      resources :cards, only: :index
    end
  end

  namespace :api, path: '/', constraints: { subdomain: 'api' } do
    resources :docs, only: [:index]
    resources :categories, only: [:index, :show], concerns: :collectable do
      get 'tree', on: :collection
    end
    concerns :collectable
  end

  resources :categories, except: :show

  resources :boards do
    post 'upload', on: :collection
    post 'hashtag', on: :collection
    member do
      get 'poll'
      get 'users'
      get 'filters'
      get 'options'
      get 'analytics'
      get 'charts'
      get 'tag_cloud'
      put 'wall'
    end
    resources :feeds do
      get 'poll', on: :member
      put 'toggle_streaming', on: :member
    end
    resources :cards, only: [:new, :create, :edit, :update, :show, :destroy] do
      post 'trust', on: :member
      post 'ban', on: :member
      post 'bulk_update', on: :collection
    end
  end

  resources :campaigns, except: :show

  devise_for :users, controllers: { registrations: 'users/registrations', omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    delete '/users/authentications/:id' => 'users/omniauth_callbacks#destroy', as: :user_authentication
  end

  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :users, except: [:show, :new, :create]

  resources :teams, except: :show

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  match 'go/:id', to: 'slideshows#deck', via: [:get, :post]
  match 'go/:id/:action', controller: 'slideshows', as: 'slideshow', via: [:get, :post], constraints: { action: /(deck|timeline|wall)/ }
  get 'embed/:id/:layout/sample', to: 'slideshows#sample', as: 'slideshow_sample', constraints: { layout: /(deck|timeline)/ }
  match 'embed/:id/:action', controller: 'slideshows', as: 'slideshow_embed', via: [:get, :post], constraints: { action: /(deck|timeline|wall)/ }, embed: true

  authenticated :user do
    root :to => "pages#dashboard", :as => "dashboard"
  end

  # You can have the root of your site routed with "root"
  root 'slideshows#show'

  match '/:id' => "shortener/shortened_urls#show", via: [:get, :post], constraints: -> (req) { req.env['PATH_INFO'] != '/websocket' }

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
