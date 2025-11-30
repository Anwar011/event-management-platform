#!/bin/bash

# Start Infrastructure Services (PostgreSQL, Redis)
# This script starts the required containers for local development

set -e

echo "🚀 Starting Infrastructure Services..."
echo ""

# Check if Docker is running
if ! docker ps > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    echo "Please start Docker first:"
    echo "  sudo systemctl start docker"
    echo "  OR"
    echo "  Start Docker Desktop"
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Start containers
echo "📦 Starting PostgreSQL and Redis containers..."
docker-compose -f docker-compose.dev.yml up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check PostgreSQL
if docker exec postgres-user-dev pg_isready -U postgres > /dev/null 2>&1; then
    echo "✅ PostgreSQL is ready"
else
    echo "⚠️  PostgreSQL is starting (may take a few more seconds)..."
fi

# Check Redis
if docker exec redis-gateway-dev redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis is ready"
else
    echo "⚠️  Redis is starting (may take a few more seconds)..."
fi

echo ""
echo "📊 Container Status:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|postgres|redis)"

echo ""
echo "✅ Infrastructure services are running!"
echo ""
echo "Next steps:"
echo "  1. Start Eureka Server"
echo "  2. Start Config Server"
echo "  3. Start User Service (will connect to PostgreSQL)"
echo "  4. Start API Gateway"
echo ""
echo "To view logs: docker-compose -f docker-compose.dev.yml logs -f"
echo "To stop: docker-compose -f docker-compose.dev.yml down"

