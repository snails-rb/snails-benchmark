# Agent notes

- Two suites, two questions: `bin/bench` measures `GET /up` (micro);
  `bin/bench-scenario` measures `GET /items/:id` (application scenario).
  Never combine their results or average them into one score.
- Fairness invariants: same host, disjoint load/server cpusets, same generator,
  warmup, rounds, and response body. Rails keeps Rails 8.1's generated
  production defaults (jemalloc, bootsnap precompile, `preload_app!` in
  cluster, three-thread default); Snails keeps its default. Thruster is left
  out so the application servers are compared directly.
- The scenario is one primary-key read. Do not call it real-world or app
  performance without naming the route and scenario.
- Results: `summary.tsv` is committed evidence; `raw/` is ignored. Record the
  exact command and version pins in docs, not in code comments.
- Peak memory is a cgroup high-water mark through the sweep, not a clean
  per-condition peak. See `docs/method.md`.
