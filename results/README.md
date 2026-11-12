# Results

Each run writes `summary.tsv`, `memory.tsv`, raw k6 output under `raw/`, and
(for the scenario suite) `run.tsv` and `db.tsv`. `raw/` is ignored by git;
keep it locally or attach it to a release when a reader needs the full k6
payload.

```
results/
  micro/
    2026-11-10-*        pre-fix run, kept for comparison
    2026-11-12/         full sweep after the fairness changes
    2026-11-12-headline/ headline-only run with the three logging-off targets
    2026-11-12-boot/    launch and idle memory
    2026-11-12-images/  image sizes
  scenario/
    2026-11-12/         item-read run
```

`bin/report` finds the newest `summary.tsv` below `results/` or accepts a run
directory explicitly. `bin/report results/micro/2026-11-12` reprints a finished
micro table without measuring again.

The 2026-11-10 micro run predates jemalloc, bootsnap precompile, and
`preload_app!` on the Rails side, and its `rails-default` used five threads.
It is history, not the current configuration.

The 2026-11-12 full sweep's `summary.tsv` and `raw/` are complete, but the run
stopped before the retained-memory pass, so it has no `memory.tsv`. Use its
`peak_mib` column. The full sweep was captured before the per-round target
rotation; the headline-only run uses the current script and writes every table.
Use the headline-only 32-connection number when quoting the claim.
