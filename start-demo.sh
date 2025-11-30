#!/bin/bash

# Event Management Platform - Demo Environment Starter
# This script starts all services needed for the demonstration

echo "🚀 STARTING EVENT MANAGEMENT PLATFORM DEMO ENVIRONMENT"
echo "======================================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Function to start service in background
start_service() {
    local service_dir="$1"
    local log_file="$2"
    local service_name="$3"

    echo -e "${BLUE}🚀 Starting $service_name...${NC}"

    # Kill any existing process for this service
    pkill -f "$service_dir" > /dev/null 2>&1 || true
    sleep 1

    # Start the service
    cd "$service_dir" && nohup mvn spring-boot:run > "../$log_file" 2>&1 &
    cd ..

    echo -e "${GREEN}✅ $service_name started${NC}"
}

# Function to wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local url="$2"
    local max_attempts=30
    local attempt=1

    echo -e "${BLUE}⏳ Waiting for $service_name...${NC}"

    while [ $attempt -le $max_attempts ]; do
        if curl -s --max-time 2 "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready!${NC}"
            return 0
        fi

        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo -e "${YELLOW}⚠️  $service_name taking longer than expected, but continuing...${NC}"
    return 1
}

# Start infrastructure
echo -e "${BLUE}🏗️  Starting infrastructure (PostgreSQL + Redis)...${NC}"
if ! docker ps --filter name=postgres --format 'table {{.Names}}' | grep -q postgres; then
    echo "Starting Docker containers..."
    ./start-infrastructure.sh > /dev/null 2>&1
    sleep 5
else
    echo "Infrastructure already running."
fi

# Verify infrastructure
echo ""
echo -e "${BLUE}🔍 Verifying infrastructure...${NC}"
if docker ps --filter name=postgres --format 'table {{.Names}}' | grep -q postgres; then
    echo -e "${GREEN}✅ PostgreSQL: RUNNING${NC}"
else
    echo -e "${YELLOW}❌ PostgreSQL: NOT RUNNING${NC}"
fi

if docker ps --filter name=redis --format 'table {{.Names}}' | grep -q redis; then
    echo -e "${GREEN}✅ Redis: RUNNING${NC}"
else
    echo -e "${YELLOW}❌ Redis: NOT RUNNING${NC}"
fi

# Start services in correct order
echo ""
echo -e "${BLUE}🚀 Starting microservices...${NC}"

# Kill any existing processes
pkill -f "spring-boot:run" > /dev/null 2>&1 || true
sleep 2

# Start services in dependency order
start_service "eureka-server" "eureka-server.log" "Eureka Server"
sleep 10

start_service "config-server" "config-server.log" "Config Server"
sleep 15

start_service "user-service" "user-service.log" "User Service"
sleep 20

start_service "api-gateway" "api-gateway.log" "API Gateway"
sleep 15

start_service "event-service" "event-service-fixed.log" "Event Service"
sleep 15

start_service "reservation-service" "reservation-service.log" "Reservation Service"
sleep 10

start_service "payment-service" "payment-service.log" "Payment Service"
sleep 10

# Wait for services to be ready
echo ""
echo -e "${BLUE}⏳ Waiting for all services to start up...${NC}"

wait_for_service "Eureka Server" "http://localhost:8761"
wait_for_service "Config Server" "http://localhost:8888/actuator/health"
wait_for_service "User Service" "http://localhost:8081/actuator/health"
wait_for_service "API Gateway" "http://localhost:8080/actuator/health"
wait_for_service "Event Service" "http://localhost:8082/actuator/health"
wait_for_service "Reservation Service" "http://localhost:8083/actuator/health"
wait_for_service "Payment Service" "http://localhost:8084/actuator/health"

echo ""
echo -e "${GREEN}🎉 ALL SERVICES STARTED SUCCESSFULLY!${NC}"
echo ""
echo -e "${BLUE}📋 Ready for demonstration. Run:${NC}"
echo "   ./demo-platform.sh          # Full demonstration"
echo "   ./demo-platform.sh quick    # Quick health check"
echo "   ./demo-platform.sh workflow # Complete workflow only"
echo ""
echo -e "${YELLOW}💡 Pro tip: The platform is now ready for stakeholders!${NC}"
