# ---------- base ----------
FROM ruby:3.4.8-alpine3.23 AS base

RUN sed -i 's|dl-cdn.alpinelinux.org|mirror.cloudflare.alpinelinux.org|g' /etc/apk/repositories

WORKDIR /app

# ---------- build ----------
FROM base AS build

RUN apk add --no-cache \
    build-base \
    ruby-dev \
    yaml-dev \
    libffi-dev \
    tzdata

COPY Gemfile Gemfile.lock ./

RUN gem install bundler -v "$(tail -n 1 Gemfile.lock)" \
 && bundle install --jobs=2 --retry=3 \
 && bundle clean --force

RUN apk --update add --no-cache \
    build-base \
    yaml-dev \
    tzdata \
    libc6-compat \
    curl \
    libffi-dev \
    ruby-dev \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    ca-certificates \
    dumb-init \
    && rm -rf /var/cache/apk/*

WORKDIR /app
COPY Gemfile* ./
RUN gem update --system 3.7.2
RUN gem install bundler -v $(tail -n 1 Gemfile.lock)
RUN bundle check || bundle install --jobs=2 --retry=3
RUN bundle clean --force
