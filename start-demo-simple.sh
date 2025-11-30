#!/bin/bash

# Simple demo starter - starts services one by one for testing

echo "🚀 SIMPLE DEMO STARTER"
echo "======================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Kill any existing services
echo -e "${BLUE}🧹 Cleaning up existing services...${NC}"
pkill -f "spring-boot:run" > /dev/null 2>&1 || true
sleep 3

# Start services sequentially
echo -e "${BLUE}🚀 Starting Eureka Server...${NC}"
cd eureka-server
mvn spring-boot:run > ../eureka-server.log 2>&1 &
EUREKA_PID=$!
cd ..
echo -e "${GREEN}✅ Eureka started (PID: $EUREKA_PID)${NC}"

sleep 10

echo -e "${BLUE}🚀 Starting Config Server...${NC}"
cd config-server
mvn spring-boot:run > ../config-server.log 2>&1 &
CONFIG_PID=$!
cd ..
echo -e "${GREEN}✅ Config Server started (PID: $CONFIG_PID)${NC}"

sleep 15

echo -e "${BLUE}🚀 Starting User Service...${NC}"
cd user-service
mvn spring-boot:run > ../user-service.log 2>&1 &
USER_PID=$!
cd ..
echo -e "${GREEN}✅ User Service started (PID: $USER_PID)${NC}"

sleep 20

echo -e "${BLUE}🚀 Starting API Gateway...${NC}"
cd api-gateway
mvn spring-boot:run > ../api-gateway.log 2>&1 &
GATEWAY_PID=$!
cd ..
echo -e "${GREEN}✅ API Gateway started (PID: $GATEWAY_PID)${NC}"

sleep 15

echo -e "${BLUE}🚀 Starting Event Service...${NC}"
cd event-service
mvn spring-boot:run > ../event-service-fixed.log 2>&1 &
EVENT_PID=$!
cd ..
echo -e "${GREEN}✅ Event Service started (PID: $EVENT_PID)${NC}"

sleep 15

echo -e "${BLUE}🚀 Starting Reservation Service...${NC}"
cd reservation-service
mvn spring-boot:run > ../reservation-service.log 2>&1 &
RESERVATION_PID=$!
cd ..
echo -e "${GREEN}✅ Reservation Service started (PID: $RESERVATION_PID)${NC}"

sleep 10

echo -e "${BLUE}🚀 Starting Payment Service...${NC}"
cd payment-service
mvn spring-boot:run > ../payment-service.log 2>&1 &
PAYMENT_PID=$!
cd ..
echo -e "${GREEN}✅ Payment Service started (PID: $PAYMENT_PID)${NC}"

echo ""
echo -e "${GREEN}🎉 ALL SERVICES STARTED!${NC}"
echo ""
echo "Process IDs:"
echo "  Eureka: $EUREKA_PID"
echo "  Config: $CONFIG_PID"
echo "  User: $USER_PID"
echo "  Gateway: $GATEWAY_PID"
echo "  Event: $EVENT_PID"
echo "  Reservation: $RESERVATION_PID"
echo "  Payment: $PAYMENT_PID"
echo ""
echo -e "${BLUE}📋 To check status: ./demo-platform.sh quick${NC}"
echo -e "${BLUE}📋 To run full demo: ./demo-platform.sh${NC}"
echo -e "${BLUE}📋 To stop all: pkill -f \"spring-boot:run\"${NC}"
