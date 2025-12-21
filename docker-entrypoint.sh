#!/bin/bash
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Debaite application...${NC}"

# Wait for PostgreSQL to be ready
echo -e "${YELLOW}Waiting for PostgreSQL to be ready...${NC}"
until pg_isready -h "$DATABASE_HOST" -U "$DATABASE_USER" -d "$DATABASE_NAME"; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 2
done

echo -e "${GREEN}PostgreSQL is ready!${NC}"

# Always get/update dependencies to ensure they match mix.lock
echo -e "${YELLOW}Installing/updating Mix dependencies...${NC}"
mix deps.get

# Create database if it doesn't exist
echo -e "${YELLOW}Creating database if it doesn't exist...${NC}"
mix ecto.create

# Run migrations
echo -e "${YELLOW}Running database migrations...${NC}"
mix ecto.migrate

# Install assets if not already done
echo -e "${YELLOW}Setting up assets...${NC}"
cd /app && mix assets.setup

echo -e "${GREEN}Setup complete! Starting Phoenix server...${NC}"

# Execute the main command
exec "$@"
