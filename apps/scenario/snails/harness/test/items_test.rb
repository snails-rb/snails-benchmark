# Item read smoke — the scenario app's one benchmark route, driven over real
# HTTP. The harness provisions db/schema.sql into its test database, so the case
# creates the row it reads.
require_relative "../boot"

if Snails::Harness.file_selected?
  class ItemReadTest < Snails::Harness::IntegrationTest
    def tables
      ["items"]
    end

    test "GET /items/:id returns the stored row" do
      created = Item.create!({
        name: "item-test",
        description: "description-test",
        price: 1234,
        status: "active"
      })
      get("/items/" + created.id.to_s)
      assert_response(:ok)
      data = JSON.parse(@response.body)
      assert_equal created.id, data["id"]
      assert_equal "item-test", data["name"]
      assert_equal "description-test", data["description"]
      assert_equal 1234, data["price"]
      assert_equal "active", data["status"]
    end
  end
end
