# snails-benchmark

Two suites measure two different questions on one Linux host:

- **micro** (`bin/bench`) — `GET /up`: the request path with no database,
  model, view, or rendering. It also covers boot, idle memory, and image size.
- **scenario** (`bin/bench-scenario`) — `GET /items/:id`: one primary-key
  database read, row mapping, and JSON serialization.

They answer different questions. Do not average the two, and do not quote one
as the other.

## Which number should I quote?

| question | suite | command |
|---|---|---|
| How fast is the framework's minimal request path? | micro | `bin/bench` |
| How much memory does the process model cost? | micro | `bin/bench` |
| How fast is a DB-backed API read? | scenario | `bin/bench-scenario` |
| How fast is a real application? | neither | measure your application |

The micro route is a no-op. Use it for framework and process-shape overhead,
not application performance. The scenario route is one read path, not a
complete application benchmark. Name the suite, the route, and the connection
count whenever you quote a number.

## Quick start

```sh
bin/bench --build
bin/bench --duration 15s --repeat 3
bin/boottime --repeat 5 --out results/micro/<run>-boot
bin/imagesize --out results/micro/<run>-images

bin/bench-scenario --build
bin/bench-scenario --duration 15s --repeat 3
```

The default micro run is eight targets × four concurrency levels × three
rounds × the duration; the scenario run is three targets × four levels × three
rounds. Both take tens of minutes on the recorded host. `--targets`, `--vus`,
`--duration`, `--repeat`, and `--out` narrow or name a run.

Requirements:

- Docker.
- `mise use -g k6@2.3.0` — the load generator. k6's own overhead differs
  between releases, so the version is pinned.
- At least 8 logical CPUs, so the generator and the app can be kept apart.
  Both scripts stop below that.
- The `snails` CLI to build the Snails images; `SNAILS_DIR` can point at a
  checkout.

Both scripts reject overlapping load/server cpusets and derive the Rails worker
count from the server cpuset, so a smaller host does not silently get the
recorded host's worker count.

## Results

Medians over three 15-second rounds from `results/micro/2026-11-12`. The rows
below are the logging-off profiles; the run also contains the logging-on and
single-worker targets. Full target list and method: [docs/micro.md](docs/micro.md).

| target | 8 | 32 | 64 | 128 | p95 at 32 | peak at 32 |
|---|---:|---:|---:|---:|---:|---:|
| baseline | 75,380 | 80,964 | 71,087 | 68,749 | 0.90 ms | 14 MiB |
| snails (logging off) | 39,499 | 50,865 | 45,205 | 40,985 | 1.34 ms | 30 MiB |
| rails-cluster (logging off) | 14,885 | 16,209 | 16,637 | 14,304 | 4.68 ms | 701 MiB |
| rails-default (logging off) | 4,518 | 4,262 | 4,486 | 4,864 | 11.19 ms | 116 MiB |

At 32 connections, Snails answered **3.14×** the requests of the Rails cluster
(50,865 vs 16,209 RPS), with p95 1.34 ms vs 4.68 ms. A headline-only run on the
same images put the same point at 2.90×, inside the run spread; quote “about
3×”, not a precise 3.1×. Against the three-thread Rails default, Snails
answered 11.9×. At 128 connections the full sweep put the cluster ratio at
2.86× (40,985 vs 14,304 RPS), while the headline-only run put it at 2.43×; the
128-connection point is more queue-sensitive and less stable than 32. The
baseline is 80,964 RPS at 32 connections, so Snails is at 63% of the
generator/HTTP ceiling and Rails cluster at 20%; neither is generator-bound.

All figures belong to this host. The micro route is a no-op; see
[What each suite measures](#what-each-suite-measures).

### Scenario

Medians over three 15-second rounds from `results/scenario/2026-11-12`.

| target | 8 | 32 | 64 | 128 | p95 at 32 | peak at 32 |
|---|---:|---:|---:|---:|---:|---:|
| baseline | 55,580 | 53,606 | 51,416 | 48,136 | 1.61 ms | 17 MiB |
| snails | 14,962 | 14,280 | 15,039 | 14,533 | 5.26 ms | 126 MiB |
| rails-cluster | 9,079 | 9,366 | 10,315 | 10,337 | 7.92 ms | 1,179 MiB |

At 32 connections, Snails answered **1.52×** the requests of the Rails cluster
(14,280 vs 9,366 RPS), with p95 5.26 ms vs 7.92 ms and peak memory 126 MiB vs
1,179 MiB (9.4×). The ratio is 1.65× at 8, 1.46× at 64, and 1.41× at 128:
the primary-key read includes the same database work on both sides, and the
database becomes the shared bottleneck. The baseline is 53,606 RPS at 32
connections; Snails is at 27% and Rails at 17%, so neither is generator-bound.
This is the application-scenario answer, and it is narrower than the `/up`
microbenchmark’s 3×.

### Boot and image

From `results/micro/2026-11-12-boot` (five rounds) and
`results/micro/2026-11-12-images`:

| target | launch to first answer | idle memory |
|---|---:|---:|
| snails | 9 ms | 13.9 MiB |
| rails-default | 1,008 ms | 94.6 MiB |
| rails-cluster | 1,033 ms | 163.0 MiB |

Launch differs by about 110×. The image sizes are 138 MiB for `snails:bench`
and 467 MiB for `rails-api:bench`; the Rails image grew after jemalloc and
bootsnap were added. Launch is the noisiest figure here: read the ratio, not
the millisecond value.

Peak memory is a cgroup high-water mark, not a clean per-condition peak. Across
the micro and scenario runs, the 32-connection ratio ranges from about 9×
(scenario, where the Snails container has accumulated more high-water memory)
to 23× (micro full sweep); treat it as a shape and a range, not a precise
claim.

The 2026-11-10 micro run under `results/micro/2026-11-10-*` predates the
fairness changes (jemalloc, bootsnap precompile, `preload_app!`, and the
three-thread default). It is kept for comparison; do not quote it as the current
configuration.

## What each suite measures

### Micro: `GET /up`

| target | shape |
|---|---|
| `baseline` | nginx static `{"status":"ok"}` |
| `snails` | one Snails process, one OS worker per server hardware thread |
| `snails-single-worker` | the same app with `SPINEL_WORKERS=1` |
| `rails-default` | Rails single process, three threads (generated default) |
| `rails-cluster` | one Puma worker per server hardware thread × 5 threads, `preload_app!`, jemalloc, bootsnap |
| `snails-no-logging` | `snails` with request logging off |
| `rails-default-no-logging` | `rails-default` with request logging off |
| `rails-cluster-no-logging` | `rails-cluster` with request logging off |

The cluster shape is a tuned comparison, not `rails new`'s default. Five
threads is Puma's default max; Rails 8.1's generated puma.rb defaults to three.
Rails keeps the generated production defaults for jemalloc and bootsnap, and
cluster mode uses `preload_app!`. See
[docs/micro.md](docs/micro.md) and [apps/rails-api/README.md](apps/rails-api/README.md).

### Scenario: `GET /items/:id`

```text
GET /items/:id
  -> primary-key SELECT on items
  -> one row mapped to the app's model type
  -> JSON response with the same five fields on both apps
```

Both apps build the same 10,000-row SQLite fixture from
`apps/scenario/snails/db/schema.sql` and `db/seed.sql`. The fixture is created
during the image build, so every container starts from the same rows. The
default targets are `baseline`, `snails`, and `rails-cluster`; `rails-default`
is available on request. The baseline is a static JSON response for the
generator ceiling; `db.tsv` records the primary-key query plan. See
[docs/scenario.md](docs/scenario.md).

## Method and fairness

Both suites use:

- the same host, response body, load generator, warmup, duration, and round
  count for every target;
- disjoint load/server cpusets, with the Rails worker count derived from the
  server set;
- a static baseline so a generator ceiling is visible rather than mistaken for
  a fast app;
- three interleaved rounds and medians; raw k6 output is written next to the
  summary;
- a one-off body check before load, with no checks in the hot loop.

The Rails side keeps the performance defaults from Rails 8.1's generated
production Dockerfile: jemalloc, precompiled bootsnap caches, and
`preload_app!` in cluster mode. `rails-default` uses the generated three-thread
default. Thruster is left out because the suites compare the application
servers directly; the generated Dockerfile would otherwise put a proxy in front
of Puma. Snails keeps its default: one process, one OS worker per core,
jemalloc.

Read [docs/method.md](docs/method.md) for the full method, including the
closed-loop caveat, the cgroup memory high-water caveat, and what the numbers
do not say.

## Layout

```text
apps/snails/              Snails app for GET /up
apps/rails-api/           Rails app for GET /up
apps/scenario/snails/     Snails app for GET /items/:id
apps/scenario/rails-api/  Rails app for GET /items/:id
baseline/nginx.conf       /up baseline
baseline/static-json.conf scenario baseline
harness/up.js             micro k6 driver
harness/scenario.js       scenario k6 driver
bin/bench                 micro suite
bin/bench-scenario        scenario suite
bin/boottime              micro boot and idle memory
bin/imagesize             micro image sizes
bin/report                median table of a finished run
docs/                     method, suite pages
results/                  committed summaries; raw/ stays local
```

Both apps answer their route with the same body. The Rails apps differ from
generated defaults in the ways listed in their READMEs.

## Limitations

- **`GET /up` only** for the micro suite. It says nothing about query
  performance, rendering, or job throughput.
- **One read path** for the scenario suite. It says nothing about writes,
  lists, authentication, caching, or jobs.
- **Absolute figures do not travel.** SMT, power limits, background work, and
  the host's memory bandwidth move them. Compare ratios and the saturation
  knee; re-measure on the target host for capacity decisions.
- **Run-to-run spread is wide.** The micro suite's round spread has reached
  31%. A 2–3× difference is readable; a 10–20% difference is not. Raise
  `--repeat` when the difference you care about is small.
- **Closed-loop load.** k6 `constant-vus` waits for each response before sending
  the next request, so p95 at saturation is optimistic compared with a fixed
  arrival rate. Add a `constant-arrival-rate` run before treating it as an SLO.
- **Peak memory is a high-water mark.** The cgroup counter is not reset between
  measurements, and idle/retained readings use a different metric (working set).
  Use it for shapes and upper bounds, not per-condition rankings.
- **SQLite scenario.** The v1 scenario uses a small page-cache-resident SQLite
  fixture. A PostgreSQL variant is the same scenario, not a second one.
- **Raw data is not committed.** `results/**/raw/` is ignored; summaries are
  committed. Keep the raw directory locally or attach it to a release.

## License

MIT. See [`LICENSE`](LICENSE).
