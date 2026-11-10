# rails-api

The Rails side of the comparison: a `rails new --api` app, with three changes so that it measures the same thing the Snails app measures.

## The three changes

**`/up` is its own controller.** Rails' built-in health route (`rails/health#show`) answers with a different body, so comparing against it would compare two different responses. `app/controllers/up_controller.rb` answers `{"status":"ok"}`, the same body the Snails health controller returns.

**`force_ssl` is off.** `config/environments/production.rb` turns on `force_ssl` and `assume_ssl`, which assume a TLS-terminating proxy in front of the app. This benchmark sends plain HTTP straight to the container, so with those on, every request would be a 301 redirect and the numbers would measure redirects.

**Health-check log silencing is off.** Generated `production.rb` sets `silence_healthcheck_path = "/up"`, which suppresses the log line a request would otherwise write. The comparison keeps the default on both sides — one log line per request — because logging cost is one of the things being separated, and a one-sided suppression would understate the Rails side.

## Ruby version

`Dockerfile` pins Ruby 4.0.9, the interpreter the recorded numbers were measured with. A floating tag would let a re-run measure a different interpreter and still be called the same test.

## Running it

`bin/bench` builds and starts this app itself:

```sh
bin/bench --build                     # both images
docker build -t rails-api:bench .     # this image only
```

To run it by hand in the shape the benchmark uses:

```sh
docker run --rm -p 3000:3000 \
  -e WEB_CONCURRENCY=0 -e RAILS_MAX_THREADS=5 \
  -e SECRET_KEY_BASE=benchmark-only-not-a-deployment-secret \
  rails-api:bench
```

`SECRET_KEY_BASE` is needed because the app boots in production mode. The value above is a dummy that exists only for local measurement; a real deployment takes it from its own environment.
