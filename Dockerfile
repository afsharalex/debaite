# Dockerfile for Debaite - Phoenix/Elixir application

# Base image with Elixir and Erlang
FROM hexpm/elixir:1.15.7-erlang-26.1.2-debian-bookworm-20231009-slim AS base

# Install system dependencies
RUN apt-get update -y && \
    apt-get install -y \
    build-essential \
    git \
    postgresql-client \
    curl \
    inotify-tools && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Install Node.js 20.x
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -f /var/lib/apt/lists/*_*

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set working directory
WORKDIR /app

# Install Mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only dev

# Copy application code
COPY . .

# Compile dependencies
RUN mix deps.compile

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose Phoenix port
EXPOSE 4000

# Set entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]

# Default command
CMD ["mix", "phx.server"]
