# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for development, not production. Use with Kamal or build'n'run by hand:
# docker build -t wallet_app .
# docker run -d -p 3000:3000 --name wallet_app wallet_app

# For a containerized production environment, see Production Dockerfile: https://guides.rubyonrails.org/production_dockerfile.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
FROM ruby:3.3.0-slim

# Rails app lives here
WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy Gemfile and install dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the rest of the application
COPY . .

# Add a script to be executed every time the container starts
COPY bin/docker-entrypoint /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint

EXPOSE 3000

# Configure the main process to run when running the image
ENTRYPOINT ["docker-entrypoint"]
CMD ["rails", "server", "-b", "0.0.0.0"]
