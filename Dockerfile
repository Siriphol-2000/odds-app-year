# syntax = docker/dockerfile:1

# Build Stage 1: Base image with Ruby and Alpine
ARG RUBY_VERSION=3.3.1
FROM ruby:$RUBY_VERSION-alpine as base

# Set working directory
WORKDIR /rails

# Set environment variables for production
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test"

# Build Stage 2: Dependencies and precompile assets
FROM base as build

# Install packages needed to build gems and precompile assets
RUN apk update && \
    apk add --no-cache build-base git libvips-dev pkgconf

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}/ruby/*/cache" "${BUNDLE_PATH}/ruby/*/bundler/gems/*/.git" && \
    bundle exec bootsnap precompile --gemfile

# Copy application code and precompile assets
COPY . .
RUN bundle exec bootsnap precompile app/ lib/ && \
    ./bin/rails assets:precompile

# Build Stage 3: Final production-ready image
FROM base as production

# Install necessary packages for running the app
RUN apk update && \
    apk add --no-cache curl libsqlite3 libvips-dev

# Copy built gems and precompiled assets from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create and switch to non-root user for security
RUN adduser -D -s /bin/sh rails && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp
USER rails

# Expose port 3000 and set entrypoint and command
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
