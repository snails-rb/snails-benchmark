# Benchmark method

`snails-benchmark` runs two suites. They answer different questions and their
numbers must not be combined:

- **micro** (`bin/bench`) measures `GET /up` — the request path with no
  database, model, view, or rendering.
- **scenario** (`bin/bench-scenario`) measures `GET /items/:id` — one
  primary-key database read plus row mapping and JSON serialization.

The rest of this page is the method both suites share.

## Host and CPU split

Both suites run on one Linux host with Docker and k6. The defaults reserve the
first four hardware threads (`0-3`) for the load generator and give the rest
(`4-15` on a 16-thread host) to the server containers. `--load-cpus` and
`--server-cpus` replace those sets; the scripts reject overlapping sets and
derive the Rails worker count from the server set, so a smaller host does not
silently get the recorded host's worker count.

On a 16-thread SMT host, `0-3` is two physical cores and `4-15` is six. The
method names hardware threads, not physical cores.

## Load and statistics

- k6 2.3.0, pinned through `mise`, runs `constant-vus` scenarios. It is a
  closed-loop generator: a VU waits for its response before sending the next
  request. p95 at saturation is therefore optimistic compared with a fixed
  arrival rate; add a `constant-arrival-rate` run before treating it as an SLO.
- Every target gets a warmup at 8 VUs for one full duration.
- Runs are 15–20 seconds by default. Three rounds are interleaved across
  targets; the report uses the median of each metric over the rounds. Target
  order rotates per round and VU level, so a slow within-round drift does not
  always hit the same target last.
- The baseline is an nginx static response. It shows the generator/HTTP
  ceiling for the same core split, so a slow app is not mistaken for a slow
  generator.
- `summary.tsv` keeps one row per target, concurrency level, and round. Raw k6
  JSON/logs go to `raw/` and are ignored by git; a run's summary is the
  committed evidence, and the raw directory can be attached to a release or
  kept locally.

## Throughput, latency, and errors

- `rps` is k6's `http_reqs.rate`; `p50/p95/p99` are the per-run percentiles.
- `failed_pct` is `http_req_failed`; the scripts fail a run when it is nonzero
  or when a measurement does not complete.
- Both apps answer the same body for each suite. A one-off body comparison runs
  before load; the hot loop carries no checks, because a check allocates and
  skews the number.

## Memory

- `peak_mib` samples the container's cgroup `memory.current` every 50 ms while
  the load runs. It is a **high-water mark through the sweep**, not a clean
  per-condition peak: the counter is not reset between measurements. Use it to
  compare ranges and upper bounds, not to rank 32-connection memory against a
  later 128-connection run.
- The idle and retained readings use `docker stats` working set, which excludes
  inactive file cache; the peak counter includes page cache. Do not compare a
  peak row with an idle row as if they used one metric.
- A shorter spike than 50 ms can be missed. These readings are enough to
  compare ranges, not to judge leaks.

## Boot

`bin/boottime` starts each app in a fresh container and times the first answer
to `/up`. The timer runs inside the container, so image preparation and
container creation are outside it. It measures the micro apps; a DB-backed
scenario boot is not separately timed. Launch is the noisiest figure here —
read the ratio, not the millisecond value.

## Fairness rules

The comparison gives both sides the same host, cpuset, generator, warmup,
rounds, and response body. The Rails side keeps the performance defaults from
Rails 8.1's generated production Dockerfile:

- jemalloc is preloaded.
- bootsnap caches are precompiled into the image.
- cluster mode uses `preload_app!` so workers share copy-on-write pages.
- `rails-default` uses the generated three-thread default; the cluster
  configuration uses five threads per worker and is labeled as a tuned
  configuration, not a default.
- Thruster is left out because the suites compare the application servers
  directly; the generated Dockerfile would otherwise put a proxy in front of
  Puma.

Snails keeps its own default: one process, one OS worker per core, jemalloc.

## What the numbers do not say

- Absolute RPS, memory, and boot values belong to this host and this run. Ratios
  travel better than absolutes, and even ratios move with SMT, power limits,
  and background work.
- The micro suite says nothing about databases, views, jobs, or real payloads.
- The scenario suite is one read path. It says nothing about writes, lists,
  authentication, caching, or job throughput.
- Do not average the two suites. Quote the suite and the scenario by name.
