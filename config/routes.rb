Civiccommons::Application.routes.draw do  
  match '/top_items/newest', :to=>'top_items#newest', :as =>'newest_items'
  match '/top_items/highest_rated', :to=>'top_items#highest_rated', :as =>'highest_rated_items'
  match '/top_items/most_visited', :to=>'top_items#most_visited', :as =>'most_visited_items'

  match '/mockup/:template_name', :to => 'mockups#show', :as => 'mockup'

  match '/mockups_index', :to => 'mockups#index', :as => 'mockups_index'

  match '/mockups', :to => 'mockups#frameset', :as => 'mockups'


  resources :people

  root :to => "homepage#show"
end
