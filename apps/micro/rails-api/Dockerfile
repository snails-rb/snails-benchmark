# The benchmark app image: gems installed in a build stage, then a runtime
# stage that carries only the bundle and the app.
#
# Plain `rails new --api` output, with no proxy and no asset pipeline, so the
# image stays close to what `rails new` gives a reader who repeats this. The
# generated Rails 8.1 Dockerfile's performance defaults stay in: jemalloc is
# preloaded and bootsnap caches are precompiled. Thruster is left out because
# this benchmark compares Puma's request path directly.
#
# The Ruby patch is pinned to the one the recorded numbers were measured with.
# A floating tag would let a re-run measure a different interpreter and call it
# the same test. `apps/rails-api/.ruby-version` names the host's Ruby; the
# container is what the benchmark measures, so the image pins its own.
ARG RUBY_IMAGE=ruby:4.0.9-slim-bookworm

FROM ${RUBY_IMAGE} AS build
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# build-essential and libyaml-dev are what the native gems in this Gemfile
# (puma, bootsnap, psych) compile against.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y build-essential libyaml-dev \
 && rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app
COPY Gemfile Gemfile.lock ./
ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test"
RUN bundle install

COPY . .

RUN bundle exec bootsnap precompile -j 1 --gemfile \
 && bundle exec bootsnap precompile -j 1 app/ lib/

FROM ${RUBY_IMAGE} AS runtime
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# tzdata is the zone database ActiveSupport reads; curl is only for the
# readiness probe the benchmark script runs. libjemalloc2 is Rails 8.1's
# generated production default for lower memory and latency.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y curl libjemalloc2 tzdata \
 && rm -rf /var/lib/apt/lists /var/cache/apt/archives \
 && ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so

WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    LD_PRELOAD=/usr/local/lib/libjemalloc.so \
    PORT=3000

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
