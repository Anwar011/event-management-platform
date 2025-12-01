#!/bin/bash

# Event Management Platform - Basic Workflow Test
# Tests User Registration → Login → Event Creation → Publishing

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
GATEWAY_URL="http://localhost:8080"
TIMESTAMP=$(date +%s)
USER_EMAIL="basic-workflow-$TIMESTAMP@example.com"
USER_PASSWORD="password123"
USER_FIRST_NAME="Basic"
USER_LAST_NAME="Workflow"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Helper function to make API calls and check results
test_step() {
    local step_name="$1"
    local command="$2"
    local expected_status="$3"
    local expected_content="$4"

    echo -e "\n${BLUE}▶️  Step: $step_name${NC}"
    echo -e "${YELLOW}Command: $command${NC}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    # Execute command and capture output
    local output
    output=$(eval "$command" 2>/dev/null || echo "ERROR")

    if [ "$output" = "ERROR" ]; then
        echo -e "${RED}❌ FAILED: Command execution error${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi

    # Check if expected content is present
    if [[ "$output" == *"$expected_content"* ]]; then
        echo -e "${GREEN}✅ PASSED: Found expected content '$expected_content'${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ FAILED: Expected '$expected_content', got '$output'${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

echo "🎯 EVENT MANAGEMENT PLATFORM - BASIC WORKFLOW TEST"
echo "================================================================="

# Step 1: Check service health
echo -e "\n${BLUE}🔍 INFRASTRUCTURE CHECK${NC}"
echo "================================================================="

test_step "API Gateway Health" \
    "curl -s $GATEWAY_URL/actuator/health | jq -r '.status'" \
    "200" "UP"

test_step "User Service Health" \
    "curl -s http://localhost:8081/actuator/health | jq -r '.status'" \
    "200" "UP"

test_step "Event Service Health" \
    "curl -s http://localhost:8082/actuator/health | jq -r '.status'" \
    "200" "UP"

# Step 2: User Registration
echo -e "\n${BLUE}👤 USER REGISTRATION${NC}"
echo "================================================================="

test_step "User Registration" \
    "curl -s -o /dev/null -w '%{http_code}' -X POST $GATEWAY_URL/v1/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASSWORD\",\"firstName\":\"$USER_FIRST_NAME\",\"lastName\":\"$USER_LAST_NAME\"}'" \
    "201" "201"

# Step 3: User Login
echo -e "\n${BLUE}🔐 USER LOGIN${NC}"
echo "================================================================="

LOGIN_RESPONSE=$(curl -s -X POST $GATEWAY_URL/v1/auth/login \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASSWORD\"}")

JWT_TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.token' 2>/dev/null || echo "")

if [ -n "$JWT_TOKEN" ] && [ "$JWT_TOKEN" != "null" ]; then
    echo -e "${GREEN}✅ PASSED: JWT token obtained${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Could not obtain JWT token${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 4: Create Event
echo -e "\n${BLUE}🎪 EVENT CREATION${NC}"
echo "================================================================="

EVENT_DATA="{
    \"title\": \"Basic Workflow Test Event\",
    \"description\": \"Testing basic event creation workflow\",
    \"eventType\": \"WORKSHOP\",
    \"venue\": \"Test Center\",
    \"startDate\": \"2024-12-25T14:00:00\",
    \"capacity\": 50,
    \"price\": 29.99,
    \"organizerId\": 1
}"

CREATE_EVENT_RESPONSE=$(curl -s -X POST $GATEWAY_URL/v1/events \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d "$EVENT_DATA")

EVENT_ID=$(echo $CREATE_EVENT_RESPONSE | jq -r '.id' 2>/dev/null || echo "")

if [ -n "$EVENT_ID" ] && [ "$EVENT_ID" != "null" ]; then
    echo -e "${GREEN}✅ PASSED: Event created with ID: $EVENT_ID${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Could not create event${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 5: Publish Event
echo -e "\n${BLUE}📢 EVENT PUBLISHING${NC}"
echo "================================================================="

test_step "Publish Event" \
    "curl -s -o /dev/null -w '%{http_code}' -X POST $GATEWAY_URL/v1/events/$EVENT_ID/publish -H 'Authorization: Bearer $JWT_TOKEN'" \
    "200" "200"

# Step 6: Verify Event is Published
echo -e "\n${BLUE}✅ EVENT VERIFICATION${NC}"
echo "================================================================="

EVENT_STATUS=$(curl -s -X GET "$GATEWAY_URL/v1/events/$EVENT_ID" \
    -H "Authorization: Bearer $JWT_TOKEN" | jq -r '.status' 2>/dev/null || echo "")

if [ "$EVENT_STATUS" = "PUBLISHED" ]; then
    echo -e "${GREEN}✅ PASSED: Event is published and available${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Event not published. Status: $EVENT_STATUS${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 7: Check Event Capacity
echo -e "\n${BLUE}📊 CAPACITY CHECK${NC}"
echo "================================================================="

CAPACITY_INFO=$(curl -s -X GET "$GATEWAY_URL/v1/events/$EVENT_ID/availability" \
    -H "Authorization: Bearer $JWT_TOKEN")

AVAILABLE_CAPACITY=$(echo $CAPACITY_INFO | jq -r '.availableCapacity' 2>/dev/null || echo "")

if [ "$AVAILABLE_CAPACITY" = "50" ]; then
    echo -e "${GREEN}✅ PASSED: Event capacity correctly available (50 seats)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Event capacity not available. Got: $AVAILABLE_CAPACITY${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Final Results
echo -e "\n${BLUE}=================================================================${NC}"
echo -e "${BLUE}🎯 BASIC WORKFLOW TEST RESULTS${NC}"
echo -e "${BLUE}=================================================================${NC}"

echo -e "${GREEN}✅ PASSED: $PASSED_TESTS${NC}"
echo -e "${RED}❌ FAILED: $FAILED_TESTS${NC}"
echo -e "${BLUE}📊 TOTAL: $TOTAL_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 BASIC WORKFLOW SUCCESSFUL!${NC}"
    echo -e "${GREEN}✅ User Registration → Login → Event Creation → Publishing${NC}"
    echo -e "${GREEN}🚀 Core Event Management Platform is working perfectly!${NC}"
else
    echo -e "\n${RED}⚠️  Some basic workflow steps failed. Check the output above.${NC}"
    echo -e "${YELLOW}🔧 The core platform needs debugging.${NC}"
fi

echo -e "\n${BLUE}=================================================================${NC}"
echo -e "${YELLOW}📋 Note: Reservation & Payment services need startup fixes${NC}"
echo -e "${YELLOW}🔄 Next: Fix Reservation & Payment service startup issues${NC}"

exit $FAILED_TESTS


