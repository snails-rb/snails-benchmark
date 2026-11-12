module Api
  # App-wide behavior for the benchmark's JSON resource. The scaffold's base
  # answers a missing record as 404 from one place, so the item action can use
  # the raising finder without a local nil check.
  class ApplicationController < ActionController::API
    JSON_TYPE = "application/json; charset=utf-8"

    def process_action(action_name)
      super
    rescue Sqlx::RecordNotFound
      head(:not_found, content_type: JSON_TYPE)
    end
  end
end
