Civiccommons::Application.routes.draw do
  # ----------------------------------------
  #   ROUTES README
  # ----------------------------------------
  # * In general routes go from most-to-least specific, top-to-bottom
  # * We use resource routes for all standard routes, including:
  #     :get => [:index, :show, :new, :edit], :post => :create, :put => :update, and :delete => :destroy
  # * We use the :only or :except clauses to exclude all standard routes not in use
  #     e.g. resources :some_controller, only: [:index, :show]
  # * We do not use custom routes to explicitly declare standard routes
  # * We group all custom routes based on the controller
  # * We put resource routes and generic pattern-matching routes after custom routes
  #     e.g. '/some_controller/:id' goes below '/some_controller/some_name'
  # * We use consistent syntax for route mapping
  #     e.g. get '/blah', to: 'bleep#bloop' instead of map '/blah', :to => 'bleep#bloop', :via => :get if possible

  #Application Root
  root to: "homepage#show"

 #Custom Matchers
  #Contributions
  post '/contributions/create_confirmed_contribution', to: 'contributions#create_confirmed_contribution',    as: 'create_confirmed_contribution'
  delete '/contributions/moderate/:id',                to: 'contributions#moderate_contribution',            as: 'moderate_contribution'
  delete '/contributions/:id',                         to: 'contributions#destroy',                          as: 'contribution'
  #Conversations
  match '/conversations/preview_node_contribution',    to: 'conversations#preview_node_contribution'
  get '/conversations/node_conversation',              to: 'conversations#node_conversation'
  get '/conversations/new_node_contribution',          to: 'conversations#new_node_contribution'
  get '/conversations/edit_node_contribution',         to: 'conversations#edit_node_contribution'
  get '/conversations/node_permalink/:id',             to: 'conversations#node_permalink'
  put '/conversations/update_node_contribution',       to: 'conversations#update_node_contribution'
  put '/conversations/confirm_node_contribution',      to: 'conversations#confirm_node_contribution'
  get '/conversations/responsibilities',               to: 'conversations#responsibilities',                 as: 'conversation_responsibilities'
  post '/conversations/toggle_rating',                 to: 'conversations#toggle_rating',                    as: 'conversation_contribution_toggle_rating'
  #Subscriptions
  post '/subscriptions/subscribe',                     to: 'subscriptions#subscribe'
  post '/subscriptions/unsubscribe',                   to: 'subscriptions#unsubscribe'
  #UnsubscribeDigest
  get '/unsubscribe-me/:id',                           to: 'unsubscribe_digest#unsubscribe_me',              as: 'unsubscribe_confirmation'
  put '/unsubscribe-me/:id',                           to: 'unsubscribe_digest#remove_from_digest'

  #Community
  get '/community',                                    to: 'community#index',                                as: 'community'
  #Widget
  get '/widget',                                       to: 'widget#index'

  #Static Pages
  get '/about',             to: 'static_pages#about'
  get '/blog',              to: 'static_pages#blog',                as: 'blog'
  get '/build_the_commons', to: 'static_pages#build_the_commons'
  get '/contact_us',        to: 'static_pages#contact'
  get '/faq',               to: 'static_pages#faq'
  get '/partners',          to: 'static_pages#partners'
  get '/poster',            to: 'static_pages#poster'
  get '/posters',           to: 'static_pages#poster'
  get '/press',             to: 'static_pages#in_the_news'
  get '/principles',        to: 'static_pages#principles'
  get '/team',              to: 'static_pages#team'
  get '/terms',             to: 'static_pages#terms'
  get '/jobs',              to: 'static_pages#jobs'
  get '/careers',           to: 'static_pages#jobs'

 #Devise Routes
  devise_for :people,
             :controllers => { :registrations => 'registrations', :confirmations => 'confirmations', :sessions => 'sessions' },
             :path_names => { :sign_in => 'login', :sign_out => 'logout', :password => 'secret', :confirmation => 'verification', :registration => 'register', :sign_up => 'new' }

  devise_scope :person do
    match '/people/ajax_login', :to=>'sessions#ajax_create', :via=>[:post]
  end

  #Sort and Filters
  constraints FilterConstraint do
    get 'conversations/:filter', to: 'conversations#filter', as: 'conversations_filter'
  end

#Resource Declared Routes
  #Declare genericly-matched GET routes after Filters
  resources :user, only: [:show, :update, :edit] do
    delete "destroy_avatar", on: :member
  end
  resources :issues, only: [:index, :show] do
    post 'create_contribution', on: :member
  end
  resources :conversations, only: [:index, :show, :new, :create]
  resources :regions, only: [:index, :show]
  resources :links, only: [:new, :create]
  resources :invites, only: [:new, :create]

#Namespaces
  namespace "admin" do
    root      to: "dashboard#show"
    resources :articles
    resources :conversations
    resources :issues
    resources :regions
    resources :people do
      get 'proxies',       on: :collection
      put 'lock_access',   on: :member
      put 'unlock_access', on: :member
    end
  end

  namespace "api" do
    get '/:id/conversations',                              to: 'conversations#index',  format: :json
    get '/:id/issues',                                     to: 'issues#index',         format: :json
    get '/:id/contributions',                              to: 'contributions#index',  format: :json
    get '/:id/subscriptions',                              to: 'subscriptions#index',  format: :json
  end

end
