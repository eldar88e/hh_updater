FROM ruby:3.4.6-alpine3.22 AS app

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
