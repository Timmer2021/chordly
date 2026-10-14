FROM ruby:3.3-slim

ENV RAILS_ENV="production" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="true"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libsqlite3-dev \
    libsqlite3-0 \
    curl \
    libatomic1 \
    pkg-config && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

WORKDIR /app

COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

# Delete the lockfile so dependencies are resolved fresh for your NAS
RUN sed -i '/^ruby/d' Gemfile && \
    rm -f Gemfile.lock && \
    bundle install && \
    yarn install

COPY . .

RUN chmod +x bin/*

RUN SECRET_KEY_BASE=dummy_build_key bin/rails assets:precompile

RUN mkdir -p storage

CMD ["bash", "-c", "bin/rails db:prepare && bin/rails server -b 0.0.0.0"]
