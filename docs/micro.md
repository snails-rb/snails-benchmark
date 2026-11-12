# Microbenchmark: `/up`

`bin/bench` measures the smallest request path: routing, middleware,
controller dispatch, JSON encoding, and the response write. It does not touch a
database, model, view, or job.

## Targets

| target | shape |
|---|---|
| `baseline` | nginx `return 200 '{"status":"ok"}'` |
| `snails` | one Snails process, one OS worker per server hardware thread |
| `snails-single-worker` | the same app with `SPINEL_WORKERS=1` |
| `rails-default` | Rails single process, three threads (generated default) |
| `rails-cluster` | one Puma worker per server hardware thread × 5 threads, `preload_app!`, jemalloc, bootsnap |
| `snails-no-logging` | `snails` with `SNAILS_LOG_LEVEL=fatal` |
| `rails-default-no-logging` | `rails-default` with `RAILS_LOG_LEVEL=fatal` |
| `rails-cluster-no-logging` | `rails-cluster` with `RAILS_LOG_LEVEL=fatal` |

The cluster shape is a tuned comparison, not `rails new`'s default. The
generated puma.rb defaults to three threads; five is Puma's default max and is
used here to give the cluster a fair thread budget. Every Rails image keeps the
generated production defaults for jemalloc and bootsnap, and cluster mode uses
`preload_app!`. See `apps/rails-api/README.md` for every difference from
`rails new`.

## Run it

```sh
bin/bench --build
bin/bench --duration 15s --repeat 3
```

The default target list is the eight rows above. `--targets` narrows it,
`--vus` changes the sweep, and `--out` names the result directory. Results are
written under `results/micro/<UTC timestamp>/`. For a headline-only run with
the logging-off profiles:

```sh
bin/bench --targets baseline,snails-no-logging,rails-cluster-no-logging \
  --duration 15s --repeat 3
```

`bin/boottime` and `bin/imagesize` cover this suite's other claims:

```sh
bin/boottime --repeat 5 --out results/micro/<run>-boot
bin/imagesize --out results/micro/<run>-images
```

## What it measures

Use this suite for framework request-path overhead, process/thread shape, boot,
idle memory, and image size. Do not use it for application performance. The
route is a no-op, and the shared HTTP, kernel, Docker port, and k6 costs are a
large share of each request.

## Results

- `results/micro/2026-11-12/` — full sweep after the fairness changes
  (jemalloc, bootsnap, `preload_app!`, three-thread default, and the corrected
  labels). The root README table uses its medians.
- `results/micro/2026-11-12-headline/` — the headline-only run with the three
  logging-off targets.
- `results/micro/2026-11-12-boot/` and `results/micro/2026-11-12-images/` —
  launch/idle memory and image sizes for the current images.
- `results/micro/2026-11-10-*` — the pre-fix run, kept for comparison. Its Rails
  side lacked jemalloc, bootsnap, and preload, and its `rails-default` used five
  threads; do not quote it as the current configuration.

The current launch figures are 9 ms for Snails, 1,008 ms for the three-thread
Rails default, and 1,033 ms for the cluster; idle memory is 13.9, 94.6, and
163.0 MiB. Launch differs by about 110×. Image sizes are 138 MiB and 467 MiB.
