#!/bin/bash
# Production deployment script for Stop & Dance
# Usage: ./scripts/deploy.sh

set -e

echo "=== Stop & Dance Production Deployment ==="
echo ""

# Check .env exists
if [ ! -f ".env" ]; then
    echo "ERROR: .env file not found!"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Check required environment variables
source .env
REQUIRED_VARS=("DB_PASSWORD" "ADMIN_USERNAME" "ADMIN_PASSWORD" "SECRET_KEY_BASE")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: $var not set in .env"
        exit 1
    fi
done

echo "✓ Environment variables validated"
echo ""

# Pull latest code
echo "Pulling latest code from git..."
git pull origin main

# Build and start containers
echo "Building Docker images..."
docker compose build

echo "Starting containers..."
docker compose up -d

# Wait for database to be ready
echo "Waiting for database..."
sleep 5

# Run migrations
echo "Running database migrations..."
docker compose exec web bundle exec rails db:migrate

# Check container status
echo ""
echo "=== Container Status ==="
docker compose ps

echo ""
echo "=== Deployment Complete ==="
echo "Application should be available at http://localhost:8080"
echo "Admin panel: http://localhost:8080/admin"
echo ""
echo "To view logs: docker compose logs -f"
echo "To check Solid Queue jobs: docker compose exec jobs bundle exec rake solid_queue:info"
