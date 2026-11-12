Rails.application.routes.draw do
  # The one measured route. /up stays as the app's health endpoint.
  get "up", to: "up#show"
  get "items/:id", to: "items#show"
end
