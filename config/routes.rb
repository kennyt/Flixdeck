Topofbarrel::Application.routes.draw do
  root to: 'movies#show'
  resources :movies, :only => [:index]
  match '/movie' => 'movies#show'
  match '/movie/get_reviews' => 'movies#get_reviews'
end
