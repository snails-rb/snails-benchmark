# Application scenario: `GET /items/:id`

`bin/bench-scenario` measures one read path that includes the data layer:

```text
GET /items/:id
  -> primary-key SELECT on items
  -> one row mapped to the app's model type
  -> JSON response with the same five fields on both apps
```

It is intentionally one route, one table, and one query. It is not a general
application benchmark.

## Fixture

Both apps build the same database at image build time from the Snails app's
schema and seed:

- `apps/scenario/snails/db/schema.sql`
- `apps/scenario/snails/db/seed.sql`

The `items` table has `id, name, description, price, status` and 10,000
deterministic rows. The load generator draws ids from `1..10000`; every request
is a primary-key equality. `db.tsv` records the query plan for the run.

SQLite is the v1 database. The scenario measures the framework path with a
small, page-cache-resident fixture. A PostgreSQL variant is future work; it
would be the same scenario, not a second one. Absolute numbers belong to the
chosen database and host.

## Apps

- `apps/scenario/snails/` — Snails app with `Item` model and
  `GET /items/:id`.
- `apps/scenario/rails-api/` — Rails API app with ActiveRecord, `Item` model,
  and the same response shape.

The Rails image is built from `apps/scenario` so it can copy the shared schema
and seed under `snails/db/`. It keeps the generated Rails 8.1 production
defaults (jemalloc, bootsnap) and enables `preload_app!` in cluster mode.

The database pool is sized so the headline 32-connection run does not queue on
the pool: Rails cluster has 12 workers × 5 connections, and Snails sets
`DATABASE_POOL_SIZE` to the same 60. At 128 connections both can queue; report
that rather than hide it.

## Baseline

`baseline/static-json.conf` returns item 1's body for any `/items/<id>`.
It shows the generator/HTTP ceiling for the response size. It is not a database
baseline; the app and DB costs are visible in the app targets and `db.tsv`.

## Run it

```sh
bin/bench-scenario --build
bin/bench-scenario --duration 15s --repeat 3
```

The default targets are `baseline`, `snails`, and `rails-cluster`;
`rails-default` is available when you add it to `--targets`. `--logging on|off` switches the request-logging
profile; the headline uses `off`. Results are written under
`results/scenario/<UTC timestamp>/`.

Readiness and the fixture check use `/items/1`, not `/up`: a health endpoint
does not prove the database path is ready. The check compares the canonical
JSON body before load, then the hot loop runs without checks.

## Results

The current item-read run is `results/scenario/2026-11-12-core-858`, with the
release-image 32-connection recheck in `results/scenario/2026-11-12-core-v0483`;
their medians are in the root README. `summary.tsv`, `memory.tsv`, `run.tsv`,
`db.tsv`, and the raw k6 output are written together, so a later reader can
re-check the query plan and the exact run settings. At 32 connections the ratio
is 3.09× (35,610 vs 11,509 RPS); the single-row read is no longer narrower than
the `/up` microbenchmark, so the framework's relative throughput holds up on
this database path.

## What it measures

Use this suite for one representative API read path: database connection/pool,
primary-key query, row mapping, and JSON serialization. It does not measure
writes, list endpoints, authentication, rendering, caching, or jobs. If the
database is the bottleneck, the framework ratio can shrink; that is a valid
result, and `db.tsv` plus the target throughput make it visible.
