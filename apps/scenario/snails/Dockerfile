# syntax=docker/dockerfile:1.7
# check=error=true

# The app image: compile the native binary in the published spinel build image,
# then run it on a minimal Debian runtime. The build image is build-only; the
# runtime stage is app-owned.
#
# Build through bin/build-image or bin/compose, which pass the pins as build
# args and vendor snails-core/ into the context. A bare `docker build` fails
# at the toolchain pull because SPINEL_REV defaults to the sentinel `unset`.
ARG SPINEL_REV=unset

FROM ghcr.io/snails-rb/spinel:${SPINEL_REV} AS app-build

ARG APP_NAME=unset

# snails-core/ is assembled by `snails sync` in bin/build-image; the committed
# gen/* files are the require lists spinel's AOT graph needs. The build stage
# adds nothing else.
WORKDIR /app
COPY . .

RUN --mount=type=cache,target=/root/.cache \
    test "$APP_NAME" != "unset" || { echo "APP_NAME build arg is required — run bin/build-image" >&2; exit 1; } \
 && spin build \
 && test -x "build/bin/${APP_NAME}"

FROM debian:bookworm-slim AS runtime

ARG APP_NAME=unset
ARG SNALS_REV=unset
ARG SPINEL_REV=unset

# Runtime packages: the binary's dynamic links — jemalloc, OpenSSL,
# libstdc++ — plus the DB client package (its CLI is what the in-container
# migration runner shells out to, and it ships the client library the
# binary links), tzdata (boot requires it), and curl for the healthcheck.
# Add the matching runtime package when the app adds a native package.
RUN apt-get update -qq \
 && apt-get install --no-install-recommends -y \
      ca-certificates \
      curl \
      libjemalloc2 \
      libssl3 \
      libstdc++6 \
      passwd \
      tzdata \
      sqlite3 \
 && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN useradd --create-home --uid 10001 app \
 && mkdir -p /app /snails/storage \
 && chown -R app:app /app /snails

WORKDIR /app

COPY --chown=app:app --from=app-build "/app/build/bin/${APP_NAME}" /usr/local/bin/app

# The in-container migration runner (docker compose run app snails migrate …):
# the snails CLI that bin/build-image/bin/compose stage into the context (the
# whole tree, under build/image-context/), the inputs the runner reads
# (adapter config, DB ownership pins, the migration files), and the CLI on
# PATH. There is no entrypoint shim: CMD is the app, and a one-off command
# replaces CMD, so the standard `compose run <service> <command>` form runs
# the runner by name.
COPY --from=app-build /app/build/image-context/snails /usr/local/lib/snails
RUN ln -s /usr/local/lib/snails/bin/snails /usr/local/bin/snails
COPY --from=app-build /app/config/database.rb /app/config/database.rb
COPY --from=app-build /app/pins.toml /app/pins.toml
COPY --from=app-build /app/db/migrate /app/db/migrate
COPY --from=app-build /app/db/schema.sql /app/db/schema.sql
COPY --from=app-build /app/db/seed.sql /app/db/seed.sql

# The read path must not depend on a startup migration or a writable volume.
# The image carries a fresh seeded database; every container starts from the
# same 10,000 rows. The file stays writable because SQLite's WAL open needs it,
# and the app declares only the read route.
RUN mkdir -p /app/storage \
 && sqlite3 /app/storage/bench.sqlite3 < /app/db/schema.sql \
 && sqlite3 /app/storage/bench.sqlite3 < /app/db/seed.sql \
 && chown -R app:app /app/storage \
 && chmod 644 /app/storage/bench.sqlite3

USER app

ENV SNAILS_ENV=production \
    PORT=3000

# A failed `migrate check` prints this command for the host shell: inside the
# container a bare `snails migrate apply` would target the development
# database, not the deployed one. The default is the compose recipe's one-off
# form; another recipe overrides it with its own.
ENV SNAILS_MIGRATE_REPAIR="bin/compose run --rm app snails migrate apply"

ENV DATABASE_PATH=/app/storage/bench.sqlite3

EXPOSE 3000

LABEL snails.rev="${SNALS_REV}" \
      snails.spinel_rev="${SPINEL_REV}"

# Start the app by default; `docker compose run <service> <command>` replaces
# this, so the migration runner is one standard one-off command away.
CMD ["/usr/local/bin/app"]
