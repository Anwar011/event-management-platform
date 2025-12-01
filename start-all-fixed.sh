#!/bin/bash
set -e

echo "Starting services..."

# Function to start a service
start_app() {
    service=$1
    log=$2
    echo "Starting $service..."
    cd $service
    nohup mvn spring-boot:run > ../$log 2>&1 &
    cd ..
    echo "$service started in background."
}

# Start Eureka
start_app "eureka-server" "eureka-server.log"
sleep 15

# Start Config
start_app "config-server" "config-server.log"
sleep 15

# Start User
start_app "user-service" "user-service.log"
sleep 15

# Start Gateway
start_app "api-gateway" "api-gateway.log"
sleep 15

# Start Event
start_app "event-service" "event-service.log"
sleep 15

# Start Reservation
start_app "reservation-service" "reservation-service.log"
sleep 10

# Start Payment
start_app "payment-service" "payment-service.log"
sleep 10

echo "All services started. Waiting for them to initialize..."
