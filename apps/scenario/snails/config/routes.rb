# The route table only — controllers load through gen/controllers.rb.
#
# The benchmark's application scenario is the single read path below. /up stays
# because every Snails app serves it and the harness uses it.
module Snails
  module RouteTable
    def self.table
      [
        get("/up", Snails::HealthController, :show),
        get("/items/:id", Api::ItemsController, :show)
      ]
    end
  end
end
