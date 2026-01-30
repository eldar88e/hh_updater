# ---------- base ----------
FROM ruby:3.4.8-alpine3.23 AS base

WORKDIR /app

# ---------- build ----------
FROM base AS build

RUN apk add --no-cache \
    build-base \
    yaml-dev \
    libffi-dev \
    tzdata \
    && rm -rf /var/cache/apk/*

COPY Gemfile Gemfile.lock ./

RUN gem install bundler -v "$(tail -n 1 Gemfile.lock)" \
 && bundle install --jobs=2 --retry=3 \
 && bundle clean --force

# ---------- runtime ----------
FROM base AS app

RUN apk add --no-cache \
    chromium-swiftshader \
    nss \
    freetype \
    harfbuzz \
    ttf-freefont \
    ca-certificates \
    dumb-init \
    tzdata \
    libc6-compat \
    curl \
    && rm -rf /var/cache/apk/*

COPY --from=build /usr/local/bundle /usr/local/bundle
