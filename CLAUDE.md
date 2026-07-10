# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project state

This is a Rails 8.1 application generated from `rails new` and not yet customized beyond its
database configuration. There are no models, controllers, or non-default routes yet — the app is
a starting point (repo name: `rails_starter`).

## Commands

- Setup (installs gems, prepares db, clears logs/tmp): `bin/setup`
- Setup without starting the server: `bin/setup --skip-server`
- Start dev server (Puma + assets/JS watchers via Foreman): `bin/dev`
- Run full CI suite locally (mirrors what CI runs): `bin/ci`
  - This runs, in order: `bin/setup --skip-server`, `bin/rubocop`, `bin/bundler-audit`,
    `bin/importmap audit`, `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`,
    `bin/rails test`, and `RAILS_ENV=test bin/rails db:seed:replant`.
  - Defined in `config/ci.rb` using `ActiveSupport::ContinuousIntegration` (invoked via `bin/ci`).
- Run the full test suite: `bin/rails test`
- Run a single test file: `bin/rails test test/models/foo_test.rb`
- Run a single test by line number: `bin/rails test test/models/foo_test.rb:12`
- Run system tests: `bin/rails test:system`
- Lint (Omakase Rubocop style): `bin/rubocop`
- Gem vulnerability audit: `bin/bundler-audit`
- Static security analysis: `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
- JS dependency audit: `bin/importmap audit`
- Rails console: `bin/rails console`
- Deploy via Kamal: `bin/kamal deploy`

## Architecture notes

- **Database is PostgreSQL, not SQLite** — this diverges from the current Rails default generator
  output. `config/database.yml` requires these env vars (see `.env` for local dev values, loaded
  via `dotenv-rails` in development/test): `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`,
  `DEV_DB_NAME`, `TEST_DB_NAME`, `PROD_DB_NAME`. There is no `database.yml.sample` fallback wired
  into `bin/setup` — the env vars must be present or `db:prepare` will fail.
- **Solid trifecta on Postgres**: `solid_queue` (jobs), `solid_cache` (Rails.cache), and
  `solid_cable` (Action Cable) all run against the database instead of Redis, each with dedicated
  schema files (`db/queue_schema.rb`, `db/cache_schema.rb`, `db/cable_schema.rb`) alongside the
  primary `db/schema.rb`. In production, Solid Queue's supervisor runs inside the Puma process by
  default (`SOLID_QUEUE_IN_PUMA: true` in `config/deploy.yml`) rather than as a separate worker
  dyno/container.
- **Assets/JS**: Propshaft (not Sprockets) + importmap-rails for JS (no bundler/Node build step).
  Hotwire (Turbo + Stimulus) is the default frontend stack.
- **Deployment** is via Kamal (`config/deploy.yml`, `.kamal/secrets`), building a Docker image
  from the root `Dockerfile` and running behind Thruster. `config/recurring.yml` defines Solid
  Queue recurring/scheduled jobs (currently only a production job-cleanup task).
