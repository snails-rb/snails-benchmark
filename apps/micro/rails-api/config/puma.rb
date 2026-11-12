# Puma settings for the benchmark app.
#
# Only the knobs the benchmark sweeps are set here; everything else stays at
# Puma's default so the numbers are not a tuned configuration's.
#
#   WEB_CONCURRENCY    worker processes; 0 = single mode (Puma's own meaning,
#                      no cluster). Default 0, matching "one process".
#   RAILS_MAX_THREADS  threads per worker; Rails 8.1's generated puma.rb
#                      defaults to 3, so the unconfigured shape uses 3. The
#                      benchmark's cluster profile sets 5 explicitly.
#
# CRuby holds a GVL, so threads alone cannot use several cores; only workers
# can. The benchmark sweeps (workers x threads) to show exactly that.
#
# `preload_app!` is the normal cluster memory shape: the master loads the app
# once and workers fork with copy-on-write pages. Without it each worker loads
# its own copy, which is the worst-case memory number, not the shape a tuned
# cluster uses.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

workers_count = Integer(ENV.fetch("WEB_CONCURRENCY", 0))
workers workers_count

preload_app! if workers_count.positive?

port ENV.fetch("PORT", 3000)
