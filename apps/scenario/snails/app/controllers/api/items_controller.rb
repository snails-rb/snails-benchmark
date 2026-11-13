module Api
  # GET /items/:id — the application-scenario benchmark's one read path.
  #
  # The response shape is explicit so both benchmark apps return the same
  # fields in the same form. The load generator only uses ids present in the
  # seeded table, so a miss is outside the measured path.
  class ItemsController < Api::ApplicationController
    def show
      item = Item.find(params["id"])
      render(json: {
        "id" => item.id,
        "name" => item.name,
        "description" => item.description,
        "price" => item.price,
        "status" => item.status
      })
    end
  end
end
