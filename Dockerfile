# syntax=docker/dockerfile:1

# Build Stage: Dependencies and Precompile Assets
FROM ruby:3.3.1-alpine AS builder

# Install required packages
RUN apk add --no-cache build-base nodejs yarn tzdata libxml2-dev libxslt-dev

# Set the working directory
WORKDIR /app

# Copy the Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Bundler and gems
RUN gem install bundler -v 2.5.18 && \
    bundle config set --local without 'development test' && \
    bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

# Set dummy secret key base for asset precompilation
ENV SECRET_KEY_BASE=dummy_secret_key

# Precompile assets
RUN bundle exec rails assets:precompile

# Production Stage: Minimal Final Image
FROM ruby:3.3.1-alpine

# Install runtime dependencies (minimal set)
RUN apk add --no-cache libxml2 libxslt nodejs tzdata

# Set working directory
WORKDIR /app

# Copy files from the build stage
COPY --from=builder /app /app
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && \
    chown -R appuser:appgroup /app
USER appuser

# Expose the app on port 3000
EXPOSE 3000

# Set environment variables for production
ENV RAILS_ENV=production

# Command to run database migrations and start the Rails server
CMD ["sh", "-c", "bundle exec rails db:migrate && bundle exec rails server -b 0.0.0.0"]

