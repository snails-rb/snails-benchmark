# rails-api (scenario)

The Rails side of the `GET /items/:id` benchmark. It enables ActiveRecord and
reads the SQLite fixture built into the image from the Snails app's
`db/schema.sql` and `db/seed.sql`.

See [`../README.md`](../README.md) for the fixture, the build commands, and the
list of differences from generated Rails defaults. The route and response shape
are in `app/controllers/items_controller.rb`.

Run it through `bin/bench-scenario` from the repository root. The image is
built with the `apps/scenario` context so it can copy the shared schema and seed
under `snails/db/`.
