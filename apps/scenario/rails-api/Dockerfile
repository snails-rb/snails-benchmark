# The benchmark's Rails image. Context is apps/scenario: the Rails app lives
# under rails-api/, and the shared SQLite schema and seed live under the Snails
# app (snails/db/) so both images build the same fixture from one source.
#
# Production defaults from Rails 8.1's generated Dockerfile are kept:
# jemalloc is preloaded and bootsnap caches are precompiled. Thruster is not
# used, because the benchmark compares Puma's request path with Snails' server
# directly; the README names that difference.
ARG RUBY_IMAGE=ruby:4.0.9-slim-bookworm

FROM ${RUBY_IMAGE} AS build
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      build-essential \
      libsqlite3-dev \
      libyaml-dev \
 && rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app
COPY rails-api/Gemfile rails-api/Gemfile.lock ./
ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"
RUN bundle install

COPY rails-api/ .
COPY snails/db/schema.sql db/bench_schema.sql
COPY snails/db/seed.sql db/bench_seed.sql

RUN bundle exec bootsnap precompile -j 1 --gemfile \
 && bundle exec bootsnap precompile -j 1 app/ lib/

FROM ${RUBY_IMAGE} AS runtime
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libsqlite3-0 \
      sqlite3 \
      tzdata \
 && rm -rf /var/lib/apt/lists /var/cache/apt/archives \
 && ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so

WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

# The fixture is built once at image build; each container starts from the
# same 10,000 rows. SQLite needs the file writable for connection setup and WAL,
# and the app has only the read route, so the fixture cannot be changed.
RUN mkdir -p storage \
 && sqlite3 storage/bench.sqlite3 < db/bench_schema.sql \
 && sqlite3 storage/bench.sqlite3 < db/bench_seed.sql \
 && chmod 644 storage/bench.sqlite3

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD=/usr/local/lib/libjemalloc.so \
    PORT=3000

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
