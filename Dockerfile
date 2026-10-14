FROM ruby:3.3-slim

# Changed to development and removed the BUNDLE_WITHOUT restriction
ENV RAILS_ENV="development" \
    BUNDLE_PATH="/usr/local/bundle" \
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

RUN mkdir -p storage

# Added db:seed to create the default users for the toolbar
CMD ["bash", "-c", "bin/rails db:prepare && bin/rails db:seed && bin/rails server -b 0.0.0.0"]
