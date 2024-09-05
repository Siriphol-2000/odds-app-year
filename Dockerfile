# syntax = docker/dockerfile:1

# Build Stage 1: Base image with Ruby (Alpine)
ARG RUBY_VERSION=3.3.1
FROM ruby:$RUBY_VERSION-alpine as base

# Rails app lives here
WORKDIR /rails

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development test" \
    SECRET_KEY_BASE_DUMMY="1"

# Build Stage 2: Dependencies and precompile assets
FROM base as build

# Install packages needed to build gems and precompile assets
RUN apk add --no-cache build-base git vips-dev

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
FROM ruby:$RUBY_VERSION-alpine as production

# Install necessary packages for running the app
RUN apk add --no-cache curl sqlite-libs vips

# Copy built gems and precompiled assets from build stage
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Create and switch to non-root user for security
RUN adduser -D rails && \
    chown -R rails:rails /rails/db /rails/log /rails/storage /rails/tmp
USER rails

# Expose port 3000 and set entrypoint and command
EXPOSE 3000
ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]