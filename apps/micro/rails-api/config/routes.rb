Rails.application.routes.draw do
  # The comparison endpoint. Rails' own /up (rails/health#show) answers a
  # different body, so the benchmark owns this one instead.
  get "up", to: "up#show"
end
