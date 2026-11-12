# rails-api

The Rails side of the `/up` microbenchmark: a `rails new --api` app, trimmed
and configured so it measures the same request path as the Snails app.

## Differences from generated `rails new --api`

- **No ActiveRecord.** `/up` touches no database, so the app removes the
  ActiveRecord railtie to keep boot and memory focused on the request path.
- **`/up` is its own controller.** Rails' built-in health route
  (`rails/health#show`) answers a different body, so
  `app/controllers/up_controller.rb` answers `{"status":"ok"}`, the same body
  the Snails health controller returns.
- **`force_ssl` is off.** Generated `production.rb` turns on `force_ssl` and
  `assume_ssl`, which assume a TLS-terminating proxy. The benchmark sends plain
  HTTP straight to the container, so with them on every request would be a 301
  redirect.
- **Health-check log silencing is off.** Generated `production.rb` sets
  `silence_healthcheck_path = "/up"`, which suppresses the request log line.
  The comparison keeps one log line per request on both sides, because the
  benchmark separates logging cost.
- **Puma is direct, without Thruster.** The generated Rails 8.1 Dockerfile
  runs `bin/thrust` in front of Puma. The microbenchmark compares the two
  application servers directly, so this image starts Puma itself.
- **The generated production defaults stay in.** The image preloads jemalloc
  and precompiles the bootsnap caches, as the generated Dockerfile does.
  `config/puma.rb` enables `preload_app!` in cluster mode, Rails' normal
  memory-sharing shape.
- **Threads and workers are set by the benchmark.** The generated puma.rb
  defaults to three threads. `bin/bench` runs `rails-default` with three and
  `rails-cluster` with twelve workers and five threads per worker; the cluster
  shape is a tuned comparison, not `rails new`'s default.

## Ruby version

`Dockerfile` pins Ruby 4.0.9, the interpreter the recorded numbers were
measured with. A floating tag would let a re-run measure a different
interpreter and still be called the same test.

## Running it

`bin/bench` builds and starts this app itself:

```sh
bin/bench --build                     # both microbenchmark images
docker build -t rails-api:bench .     # this image only
```

To run it by hand in the generated default shape:

```sh
docker run --rm -p 3000:3000 \
  -e WEB_CONCURRENCY=0 -e RAILS_MAX_THREADS=3 \
  -e SECRET_KEY_BASE=benchmark-only-not-a-deployment-secret \
  rails-api:bench
```

`SECRET_KEY_BASE` is needed because the app boots in production mode. The
value above is a dummy that exists only for local measurement; a real
deployment takes it from its own environment.
