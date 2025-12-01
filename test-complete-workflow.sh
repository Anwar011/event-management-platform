#!/bin/bash

# Event Management Platform - Complete Workflow Test
# Tests the entire booking flow: User → Event → Reservation → Payment

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
USER_EMAIL="workflow-test-$TIMESTAMP@example.com"
USER_PASSWORD="password123"
USER_FIRST_NAME="Workflow"
USER_LAST_NAME="Test"

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

echo "🎯 EVENT MANAGEMENT PLATFORM - COMPLETE WORKFLOW TEST"
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

test_step "Reservation Service Health" \
    "curl -s http://localhost:8083/actuator/health | jq -r '.status'" \
    "200" "UP"

test_step "Payment Service Health" \
    "curl -s http://localhost:8084/actuator/health | jq -r '.status'" \
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
    \"title\": \"Complete Workflow Test Event\",
    \"description\": \"Testing the complete booking workflow\",
    \"eventType\": \"WORKSHOP\",
    \"venue\": \"Test Center\",
    \"startDate\": \"2026-06-25T14:00:00\",
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
    exit 1
fi

# Step 5: Publish Event
echo -e "\n${BLUE}📢 EVENT PUBLISHING${NC}"
echo "================================================================="

test_step "Publish Event" \
    "curl -s -o /dev/null -w '%{http_code}' -X POST $GATEWAY_URL/v1/events/$EVENT_ID/publish -H 'Authorization: Bearer $JWT_TOKEN'" \
    "200" "200"

# Step 6: Create Reservation
echo -e "\n${BLUE}🎫 RESERVATION CREATION${NC}"
echo "================================================================="

# First, get user ID from JWT token or use a default (we'll use user ID 1 for simplicity)
USER_ID=1

RESERVATION_DATA="{
    \"userId\": $USER_ID,
    \"eventId\": $EVENT_ID,
    \"quantity\": 2,
    \"idempotencyKey\": \"workflow-test-$TIMESTAMP\"
}"

CREATE_RESERVATION_RESPONSE=$(curl -s -X POST $GATEWAY_URL/v1/reservations \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d "$RESERVATION_DATA")

RESERVATION_ID=$(echo $CREATE_RESERVATION_RESPONSE | jq -r '.reservationId' 2>/dev/null || echo "")
RESERVATION_TOTAL=$(echo $CREATE_RESERVATION_RESPONSE | jq -r '.totalPrice' 2>/dev/null || echo "0")

if [ -n "$RESERVATION_ID" ] && [ "$RESERVATION_ID" != "null" ]; then
    echo -e "${GREEN}✅ PASSED: Reservation created with ID: $RESERVATION_ID${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Could not create reservation${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 7: Create Payment Intent
echo -e "\n${BLUE}💰 PAYMENT INTENT CREATION${NC}"
echo "================================================================="

PAYMENT_INTENT_DATA="{
    \"reservationId\": \"$RESERVATION_ID\",
    \"userId\": $USER_ID,
    \"amount\": $RESERVATION_TOTAL,
    \"currency\": \"USD\",
    \"description\": \"Payment for Complete Workflow Test Event\",
    \"idempotencyKey\": \"payment-workflow-$TIMESTAMP\"
}"

CREATE_INTENT_RESPONSE=$(curl -s -X POST $GATEWAY_URL/v1/payments/intents \
    -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $JWT_TOKEN" \
    -d "$PAYMENT_INTENT_DATA")

INTENT_ID=$(echo $CREATE_INTENT_RESPONSE | jq -r '.intentId' 2>/dev/null || echo "")

if [ -n "$INTENT_ID" ] && [ "$INTENT_ID" != "null" ]; then
    echo -e "${GREEN}✅ PASSED: Payment intent created with ID: $INTENT_ID${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Could not create payment intent${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 8: Capture Payment
echo -e "\n${BLUE}💳 PAYMENT CAPTURE${NC}"
echo "================================================================="

CAPTURE_RESPONSE=$(curl -s -X POST "$GATEWAY_URL/v1/payments/intents/$INTENT_ID/capture?idempotencyKey=capture-workflow-$TIMESTAMP" \
    -H "Authorization: Bearer $JWT_TOKEN")

PAYMENT_STATUS=$(echo $CAPTURE_RESPONSE | jq -r '.status' 2>/dev/null || echo "")

if [ "$PAYMENT_STATUS" = "SUCCEEDED" ]; then
    echo -e "${GREEN}✅ PASSED: Payment captured successfully${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Payment capture failed or returned status: $PAYMENT_STATUS${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 9: Verify Reservation Confirmation
echo -e "\n${BLUE}✅ RESERVATION CONFIRMATION VERIFICATION${NC}"
echo "================================================================="

RESERVATION_STATUS=$(curl -s -X GET "$GATEWAY_URL/v1/reservations/$RESERVATION_ID" \
    -H "Authorization: Bearer $JWT_TOKEN" | jq -r '.status' 2>/dev/null || echo "")

if [ "$RESERVATION_STATUS" = "CONFIRMED" ]; then
    echo -e "${GREEN}✅ PASSED: Reservation confirmed after payment${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Reservation not confirmed. Status: $RESERVATION_STATUS${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Step 10: Verify Event Capacity Updated
echo -e "\n${BLUE}📊 CAPACITY VERIFICATION${NC}"
echo "================================================================="

CAPACITY_INFO=$(curl -s -X GET "$GATEWAY_URL/v1/events/$EVENT_ID/availability" \
    -H "Authorization: Bearer $JWT_TOKEN")

AVAILABLE_CAPACITY=$(echo $CAPACITY_INFO | jq -r '.availableCapacity' 2>/dev/null || echo "")

if [ "$AVAILABLE_CAPACITY" = "48" ]; then  # 50 - 2 reserved
    echo -e "${GREEN}✅ PASSED: Event capacity correctly updated (48 available)${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
else
    echo -e "${RED}❌ FAILED: Event capacity not updated correctly. Available: $AVAILABLE_CAPACITY${NC}"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
fi

# Final Results
echo -e "\n${BLUE}=================================================================${NC}"
echo -e "${BLUE}🎯 WORKFLOW TEST RESULTS${NC}"
echo -e "${BLUE}=================================================================${NC}"

echo -e "${GREEN}✅ PASSED: $PASSED_TESTS${NC}"
echo -e "${RED}❌ FAILED: $FAILED_TESTS${NC}"
echo -e "${BLUE}📊 TOTAL: $TOTAL_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 COMPLETE WORKFLOW SUCCESSFUL!${NC}"
    echo -e "${GREEN}🚀 The Event Management Platform is working perfectly!${NC}"
    echo -e "${GREEN}✅ User Registration → Event Creation → Reservation → Payment → Confirmation${NC}"
else
    echo -e "\n${RED}⚠️  Some workflow steps failed. Check the output above.${NC}"
    echo -e "${YELLOW}🔧 The platform needs debugging for full functionality.${NC}"
fi

echo -e "\n${BLUE}=================================================================${NC}"

exit $FAILED_TESTS


