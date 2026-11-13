# Scenario apps

Two apps serve one benchmark route with the same body:

```text
GET /items/:id -> {"id":..., "name":..., "description":..., "price":..., "status":...}
```

- `snails/` — Snails app, one process, SQLite, `Item` model.
- `rails-api/` — Rails API app with ActiveRecord, SQLite, `Item` model.

Both images build the same 10,000-row fixture from `snails/db/schema.sql` and
`snails/db/seed.sql`. The fixture is created during the image build; no migration
or seed runs at benchmark time, so every container starts from the same rows.

## Build

```sh
# Snails image (context: its app root)
( cd snails && IMAGE=snails-scenario bin/build-image --tag bench )

# Rails image (context: apps/scenario, so it can copy snails/db/)
docker build -f rails-api/Dockerfile -t rails-scenario:bench .
```

`bin/bench-scenario --build` runs both commands.

## Differences from generated defaults

The Rails app keeps the generated Rails 8.1 production defaults for jemalloc,
bootsnap caches, and cluster `preload_app!`. It differs in three ways:

- ActiveRecord is enabled, because this scenario reads a real table.
- Thruster is left out; the comparison targets Puma directly.
- `config/database.yml` points at the fixture built into the image.

The Snails app keeps the scaffold's table-oriented model layer and SQLite
adapter. `DATABASE_POOL_SIZE` is set by the benchmark to match the Rails
cluster's total connection count at the headline concurrency.
