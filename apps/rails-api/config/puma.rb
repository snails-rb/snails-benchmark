# Puma settings for the benchmark app.
#
# Only the two knobs the benchmark sweeps are set here; everything else stays
# at Puma's default so the numbers are not a tuned configuration's.
#
#   WEB_CONCURRENCY    worker processes; 0 = single mode (Puma's own meaning,
#                      no cluster). Default 0, matching "one process".
#   RAILS_MAX_THREADS  threads per worker (default 5)
#
# CRuby holds a GVL, so threads alone cannot use several cores; only workers
# can. The benchmark sweeps (workers x threads) to show exactly that.
threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
threads threads_count, threads_count

workers Integer(ENV.fetch("WEB_CONCURRENCY", 0))

port ENV.fetch("PORT", 3000)
