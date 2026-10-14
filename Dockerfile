# Use standard Ruby instead of the custom/experimental image
FROM ruby:3.3-slim

# Set standard production environment variables
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    RAILS_SERVE_STATIC_FILES="true"

# Install all necessary system dependencies cleanly (No BuildKit required)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    git \
    libsqlite3-dev \
    libsqlite3-0 \
    curl \
    libatomic1 \
    pkg-config && \
    # Install Node.js and Yarn
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

# Create and set the working directory
WORKDIR /app

# Copy dependency files first to take advantage of Docker caching
COPY Gemfile Gemfile.lock ./
COPY package.json yarn.lock ./

# Install Ruby gems and Javascript packages
RUN bundle install && \
    yarn install

# Copy the rest of the application code
COPY . .

# Ensure Rails scripts are executable
RUN chmod +x bin/*

# Precompile assets for production (Requires a dummy secret for the build step)
RUN SECRET_KEY_BASE=dummy_build_key bin/rails assets:precompile

# Ensure the storage directory exists for the SQLite database
RUN mkdir -p storage

# Automatically setup/update the database, then start the server
CMD ["bash", "-c", "bin/rails db:prepare && bin/rails server -b 0.0.0.0"]
