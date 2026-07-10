# syntax=docker/dockerfile:1

# Single image shared by dev, CI, and production. Behavior differs only via
# RAILS_ENV / env vars at `docker run` / `docker compose` time, not via
# separate Dockerfiles or build stages.

ARG RUBY_VERSION=3.3.7
FROM docker.io/library/ruby:${RUBY_VERSION}-slim

# Rails app lives here
WORKDIR /rails

# System deps needed to build native gems (pg, etc.) and run the app
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      libyaml-dev \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

# Install gems first so this layer is cached unless Gemfile(.lock) changes
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
