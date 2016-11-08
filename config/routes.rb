Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  require 'sidekiq/web'
  require 'sidekiq/cron/web'

  unless Figaro.env.disable_uploads.to_b
    mount DAV4Rack::Handler.new(
      root: File.join(Rails.root, 'public', 'system'),
      root_uri_path: '/magnet',
      resource_class: UserFileResource
    ), at: '/magnet'
  end

  mount Bootsy::Engine => '/bootsy', as: 'bootsy'

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
      get 'cta', on: :member
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

  resources :users, except: :show, path: '/accounts'

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

  match '/:id' => "shortener/shortened_urls#show", via: [:get, :post], constraints: -> (req) { req.env['PATH_INFO'] != '/cable' }
end
