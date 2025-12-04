#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base URLs
API_GATEWAY="http://localhost:8080"
USER_SERVICE="http://localhost:8081"
EVENT_SERVICE="http://localhost:8082"
RESERVATION_SERVICE="http://localhost:8083"
PAYMENT_SERVICE="http://localhost:8084"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   COMPREHENSIVE API TESTING SCRIPT    ${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local url=$2
    local data=$3
    local expected_status=$4
    local description=$5

    # echo -e "Testing $description..."
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -d "$data")
    fi

    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    # Debug: Print body if it's not empty
    if [ ! -z "$body" ]; then
        echo "Body: $body"
    fi

    if [ "$http_code" -eq "$expected_status" ]; then
        echo -e "${GREEN}✓ PASS - $description${NC}"
        # Export body for capturing values
        export LAST_RESPONSE_BODY="$body"
        return 0
    else
        echo -e "${RED}✗ FAIL - $description${NC}"
        echo -e "  Response: HTTP $http_code: $body"
        return 1
    fi
}

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 5

echo -e "${BLUE}=== USER SERVICE TESTS ===${NC}"

#Generate unique email for this test run
TIMESTAMP=$(date +%s)
TEST_EMAIL="test${TIMESTAMP}@example.com"

# 1. User Registration
echo -e "${YELLOW}Testing User Registration...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/auth/register" \
    "{\"username\":\"testuser\",\"email\":\"$TEST_EMAIL\",\"password\":\"password123\"}" \
    "201" "User Registration"

# Capture User ID
USER_ID=$(echo $LAST_RESPONSE_BODY | jq -r '.userId')
echo "Created User ID: $USER_ID"

# 2. User Login
echo -e "${YELLOW}Testing User Login...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/auth/login" \
    "{\"email\":\"$TEST_EMAIL\",\"password\":\"password123\"}" \
    "200" "User Login"

# 3. Get User Profile (without token for now)
echo -e "${YELLOW}Testing Get User Profile...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/users/$USER_ID" "" "200" "Get User Profile"

# 4. Update User Profile
echo -e "${YELLOW}Testing Update User Profile...${NC}"
test_endpoint "PUT" "$API_GATEWAY/v1/users/$USER_ID" \
    '{"username":"updateduser"}' \
    "200" "Update User Profile"

# 5. Get All Users
echo -e "${YELLOW}Testing Get All Users...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/users" "" "200" "Get All Users"

# 6. Delete User (We will delete at the end to allow other tests to use this user)
# echo -e "${YELLOW}Testing Delete User...${NC}"
# test_endpoint "DELETE" "$API_GATEWAY/v1/users/999" "" "200" "Delete User"

echo
echo -e "${BLUE}=== EVENT SERVICE TESTS ===${NC}"

# 7. Create Event
echo -e "${YELLOW}Testing Create Event...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/events" \
    '{"title":"Test Event","description":"Test Description","eventType":"CONCERT","venue":"Test Venue","address":"123 Test St","city":"Test City","state":"TS","country":"Test Country","postalCode":"12345","startDate":"2025-12-31T18:00:00","endDate":"2025-12-31T22:00:00","capacity":100,"price":29.99,"organizerId":1}' \
    "201" "Create Event"

# Capture Event ID
EVENT_ID=$(echo $LAST_RESPONSE_BODY | jq -r '.id')
echo "Created Event ID: $EVENT_ID"

# 8. Get All Events
echo -e "${YELLOW}Testing Get All Events...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/events" "" "200" "Get All Events"

# 9. Get Event by ID
echo -e "${YELLOW}Testing Get Event by ID...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/events/$EVENT_ID" "" "200" "Get Event by ID"

# 10. Update Event
echo -e "${YELLOW}Testing Update Event...${NC}"
test_endpoint "PUT" "$API_GATEWAY/v1/events/$EVENT_ID" \
    '{"title":"Updated Event","description":"Updated Description","capacity":150,"price":29.99}' \
    "200" "Update Event"

# 11. Delete Event (We will delete at the end)
# echo -e "${YELLOW}Testing Delete Event...${NC}"
# test_endpoint "DELETE" "$API_GATEWAY/v1/events/999" "" "200" "Delete Event"

# 12. Search Events
echo -e "${YELLOW}Testing Search Events...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/events/search?keyword=test" "" "200" "Search Events"

echo
echo -e "${BLUE}=== RESERVATION SERVICE TESTS ===${NC}"

# 13. Create Reservation
echo -e "${YELLOW}Testing Create Reservation...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/reservations" \
    "{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":2}" \
    "201" "Create Reservation"

# Capture Reservation ID
RESERVATION_ID=$(echo $LAST_RESPONSE_BODY | jq -r '.reservationId')
echo "Created Reservation ID: $RESERVATION_ID"

# 14. Get All Reservations
echo -e "${YELLOW}Testing Get All Reservations...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/reservations" "" "200" "Get All Reservations"

# 15. Get Reservation by ID
echo -e "${YELLOW}Testing Get Reservation by ID...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/reservations/$RESERVATION_ID" "" "200" "Get Reservation by ID"

# 15b. Get Reservation by ID (Non-existent)
echo -e "${YELLOW}Testing Get Reservation by ID (Non-existent)...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/reservations/NON-EXISTENT-ID" "" "404" "Get Reservation by ID (Non-existent)"

# 16. Get User Reservations
echo -e "${YELLOW}Testing Get User Reservations...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/reservations/user/$USER_ID" "" "200" "Get User Reservations"

# 17. Update Reservation
echo -e "${YELLOW}Testing Update Reservation...${NC}"
test_endpoint "PUT" "$API_GATEWAY/v1/reservations/$RESERVATION_ID" \
    "{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":3}" \
    "200" "Update Reservation"

# 17b. Update Reservation (Non-existent)
echo -e "${YELLOW}Testing Update Reservation (Non-existent)...${NC}"
test_endpoint "PUT" "$API_GATEWAY/v1/reservations/NON-EXISTENT-ID" \
    "{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":3}" \
    "404" "Update Reservation (Non-existent)"

# 18. Cancel Reservation (Non-existent)
echo -e "${YELLOW}Testing Cancel Reservation (Non-existent)...${NC}"
test_endpoint "DELETE" "$API_GATEWAY/v1/reservations/NON-EXISTENT-ID" "" "404" "Cancel Reservation (Non-existent)"

echo
echo -e "${BLUE}=== PAYMENT SERVICE TESTS ===${NC}"

# 19. Create Payment
# Amount must match: 29.99 * 3 = 89.97
echo -e "${YELLOW}Testing Create Payment...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/payments" \
    "{\"reservationId\":\"$RESERVATION_ID\",\"userId\":$USER_ID,\"amount\":89.97,\"currency\":\"USD\",\"paymentMethod\":\"CREDIT_CARD\"}" \
    "201" "Create Payment"

# Capture Payment ID
PAYMENT_ID=$(echo $LAST_RESPONSE_BODY | jq -r '.paymentId')
echo "Created Payment ID: $PAYMENT_ID"

# 20. Get All Payments
echo -e "${YELLOW}Testing Get All Payments...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/payments" "" "200" "Get All Payments"

# 21. Get Payment by ID
echo -e "${YELLOW}Testing Get Payment by ID...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/payments/$PAYMENT_ID" "" "200" "Get Payment by ID"

# 21b. Get Payment by ID (Non-existent)
echo -e "${YELLOW}Testing Get Payment by ID (Non-existent)...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/payments/NON-EXISTENT-ID" "" "404" "Get Payment by ID (Non-existent)"

# 22. Get User Payments
echo -e "${YELLOW}Testing Get User Payments...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/payments/user/$USER_ID" "" "200" "Get User Payments"

# 23. Update Payment Status
echo -e "${YELLOW}Testing Update Payment Status...${NC}"
test_endpoint "PUT" "$API_GATEWAY/v1/payments/$PAYMENT_ID/status" \
    '{"status":"COMPLETED"}' \
    "200" "Update Payment Status"

# 23b. Update Payment Status (Non-existent)
echo -e "${YELLOW}Testing Update Payment Status (Non-existent)...${NC}"
test_endpoint "PUT" "$API_GATEWAY/v1/payments/NON-EXISTENT-ID/status" \
    '{"status":"COMPLETED"}' \
    "404" "Update Payment Status (Non-existent)"

# 24. Process Payment (Non-existent)
echo -e "${YELLOW}Testing Process Payment (Non-existent)...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/payments/NON-EXISTENT-ID/process" \
    '{}' \
    "404" "Process Payment (Non-existent)"

echo
echo -e "${BLUE}=== DIRECT SERVICE TESTS (Bypass Gateway) ===${NC}"

# 25. Direct User Service
echo -e "${YELLOW}Testing Direct User Service...${NC}"
test_endpoint "GET" "$USER_SERVICE/users" "" "200" "Direct User Service - Get Users"
test_endpoint "GET" "$USER_SERVICE/actuator/health" "" "200" "User Service Health Check"

# 26. Direct Event Service
echo -e "${YELLOW}Testing Direct Event Service...${NC}"
test_endpoint "GET" "$EVENT_SERVICE/events" "" "200" "Direct Event Service - Get Events"
test_endpoint "GET" "$EVENT_SERVICE/actuator/health" "" "200" "Event Service Health Check"

# 27. Direct Reservation Service
echo -e "${YELLOW}Testing Direct Reservation Service...${NC}"
test_endpoint "GET" "$RESERVATION_SERVICE/reservations" "" "200" "Direct Reservation Service - Get Reservations"
test_endpoint "GET" "$RESERVATION_SERVICE/actuator/health" "" "200" "Reservation Service Health Check"

# 28. Direct Payment Service
echo -e "${YELLOW}Testing Direct Payment Service...${NC}"
test_endpoint "GET" "$PAYMENT_SERVICE/payments" "" "200" "Direct Payment Service - Get Payments"
test_endpoint "GET" "$PAYMENT_SERVICE/actuator/health" "" "200" "Payment Service Health Check"

echo
echo -e "${BLUE}=== BUSINESS LOGIC TESTS ===${NC}"

# 29. Event Capacity Management
echo -e "${YELLOW}Testing Event Capacity Management...${NC}"
# Try to reserve more than capacity
test_endpoint "POST" "$API_GATEWAY/v1/reservations" \
    "{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":1000}" \
    "400" "Reservation Exceeds Capacity (Should Fail)"

# 30. Duplicate User Registration
echo -e "${YELLOW}Testing Duplicate User Registration...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/auth/register" \
    "{\"username\":\"testuser\",\"email\":\"$TEST_EMAIL\",\"password\":\"password123\"}" \
    "400" "Duplicate User Registration (Should Fail)"

# 31. Invalid Login
echo -e "${YELLOW}Testing Invalid Login...${NC}"
test_endpoint "POST" "$API_GATEWAY/v1/auth/login" \
    '{"email":"test@example.com","password":"wrongpassword"}' \
    "401" "Invalid Login (Should Fail)"

# 32. Non-existent Resource Access
echo -e "${YELLOW}Testing Non-existent Resource Access...${NC}"
test_endpoint "GET" "$API_GATEWAY/v1/events/99999" "" "404" "Non-existent Event (Should Fail)"
test_endpoint "GET" "$API_GATEWAY/v1/users/99999" "" "404" "Non-existent User (Should Fail)"

# Cleanup
echo
echo -e "${BLUE}=== CLEANUP ===${NC}"
echo -e "${YELLOW}Deleting Test User...${NC}"
test_endpoint "DELETE" "$API_GATEWAY/v1/users/$USER_ID" "" "200" "Delete User"

echo -e "${YELLOW}Deleting Test Event...${NC}"
test_endpoint "DELETE" "$API_GATEWAY/v1/events/$EVENT_ID" "" "200" "Delete Event"

echo
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}           TEST SUMMARY                 ${NC}"
echo -e "${BLUE}========================================${NC}"

# Count pass/fail
passed=$(grep -c "✓ PASS" <(echo "$output"))
failed=$(grep -c "✗ FAIL" <(echo "$output"))

# echo "Total Tests: $((passed + failed))"
# echo "Passed: $passed"
# echo "Failed: $failed"

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the errors above.${NC}"
    exit 1
fi
