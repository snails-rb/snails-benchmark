# The benchmark app image: gems installed in a build stage, then a runtime stage
# that carries only the bundle and the app.
#
# Plain `rails new --api` output, with no proxy and no asset pipeline, so the
# image stays close to what `rails new` gives a reader who repeats this.
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

FROM ${RUBY_IMAGE} AS runtime
SHELL ["/bin/bash", "-euo", "pipefail", "-c"]

# tzdata is the zone database ActiveSupport reads; curl is only for the
# readiness probe the benchmark script runs.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y curl tzdata \
 && rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    PORT=3000

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
