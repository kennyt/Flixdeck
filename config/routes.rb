Topofbarrel::Application.routes.draw do
  root to: 'movies#show'
  match '/movie' => 'movies#show'
end
