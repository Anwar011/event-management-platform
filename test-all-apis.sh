#!/bin/bash

echo "🚀 Comprehensive API Testing Script"
echo "===================================="
echo ""

API_BASE="http://localhost:8080"
TIMESTAMP=$(date +%s)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print status
print_status() {
    local status=$1
    local message=$2
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}❌ $message${NC}"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local data=$3
    local auth_header=$4
    local expected_status=$5
    local description=$6
    
    if [ -z "$expected_status" ]; then
        expected_status="200"
    fi
    
    local cmd="curl -s -w \"%{http_code}\" -o /tmp/api_response.json"
    
    if [ "$method" = "POST" ] || [ "$method" = "PUT" ]; then
        cmd="$cmd -X $method -H \"Content-Type: application/json\""
        if [ -n "$data" ]; then
            cmd="$cmd -d '$data'"
        fi
    elif [ "$method" = "DELETE" ]; then
        cmd="$cmd -X DELETE"
    else
        cmd="$cmd -X GET"
    fi
    
    if [ -n "$auth_header" ]; then
        cmd="$cmd -H \"Authorization: Bearer $auth_header\""
    fi
    
    cmd="$cmd \"$API_BASE$endpoint\""
    
    local http_code=$(eval $cmd | tail -1)
    local response=$(cat /tmp/api_response.json 2>/dev/null)
    
    if [ "$http_code" = "$expected_status" ] || [ "$http_code" = "201" ] && [ "$expected_status" = "200" ]; then
        print_status 0 "$description (HTTP $http_code)"
        echo "$response" | jq '.' 2>/dev/null | head -5 || echo "    Response: ${response:0:100}..."
        return 0
    else
        print_status 1 "$description (HTTP $http_code, expected $expected_status)"
        echo "$response" | jq '.' 2>/dev/null || echo "    Response: ${response:0:200}..."
        return 1
    fi
}

# Setup: Create test user and get token
echo -e "${CYAN}📋 Setting up test data...${NC}"
echo "===================================="

TEST_EMAIL="apitest-${TIMESTAMP}@example.com"
TEST_PASSWORD="TestPassword123"

# Register user
register_response=$(curl -s -X POST "$API_BASE/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"firstName\":\"API\",\"lastName\":\"Test\"}")

USER_ID=$(echo "$register_response" | jq -r '.id // .userId // empty' 2>/dev/null)

# Login to get token
login_response=$(curl -s -X POST "$API_BASE/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

TOKEN=$(echo "$login_response" | jq -r '.token // empty' 2>/dev/null)
if [ -z "$USER_ID" ]; then
    USER_ID=$(echo "$login_response" | jq -r '.userId // empty' 2>/dev/null)
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}❌ Failed to get authentication token. Cannot proceed with authenticated tests.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Test user created: $TEST_EMAIL (ID: $USER_ID)${NC}"
echo -e "${GREEN}✅ Authentication token obtained${NC}"
echo ""

# ============================================================================
# USER SERVICE - AUTH ENDPOINTS
# ============================================================================
echo -e "${BLUE}🔐 Testing User Service - Authentication${NC}"
echo "=============================================="

test_endpoint "GET" "/v1/auth/test" "" "" "200" "GET /auth/test"
test_endpoint "POST" "/v1/auth/simple-test" "" "" "200" "POST /auth/simple-test"
test_endpoint "POST" "/v1/auth/register" "{\"email\":\"duplicate-${TIMESTAMP}@example.com\",\"password\":\"Password123\",\"firstName\":\"Test\",\"lastName\":\"User\"}" "" "200" "POST /auth/register (new user)"
    # Test duplicate email (should return 400)
    duplicate_response=$(curl -s -X POST "$API_BASE/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"Password123\",\"firstName\":\"Test\",\"lastName\":\"User\"}" \
        -w "%{http_code}" -o /dev/null)
    if [ "$duplicate_response" = "400" ]; then
        print_status 0 "POST /auth/register (duplicate email) - Correctly rejected"
    else
        print_status 1 "POST /auth/register (duplicate email) - Expected 400, got $duplicate_response"
    fi

# ============================================================================
# USER SERVICE - USER ENDPOINTS
# ============================================================================
echo -e "\n${BLUE}👤 Testing User Service - User Management${NC}"
echo "=============================================="

test_endpoint "GET" "/v1/users/ping" "" "" "200" "GET /users/ping"
test_endpoint "GET" "/v1/users" "" "" "200" "GET /users (list all)"
# GET /users/me requires X-User-Id header (extracted from JWT by gateway)
me_response=$(curl -s -X GET "$API_BASE/v1/users/me" \
    -H "Authorization: Bearer $TOKEN" \
    -H "X-User-Id: $USER_ID" \
    -w "%{http_code}" -o /tmp/api_response.json)
http_code=$(echo "$me_response" | tail -1)
if [ "$http_code" = "200" ]; then
    print_status 0 "GET /users/me (authenticated) (HTTP $http_code)"
    cat /tmp/api_response.json | jq '.' 2>/dev/null | head -5 || echo "    Response: $(cat /tmp/api_response.json | head -c 100)..."
else
    print_status 1 "GET /users/me (authenticated) (HTTP $http_code, expected 200)"
    cat /tmp/api_response.json | jq '.' 2>/dev/null || echo "    Response: $(cat /tmp/api_response.json | head -c 200)..."
fi
test_endpoint "GET" "/v1/users/$USER_ID" "" "" "200" "GET /users/{id}"
test_endpoint "PUT" "/v1/users/$USER_ID" "{\"email\":\"$TEST_EMAIL\",\"firstName\":\"Updated\",\"lastName\":\"Name\",\"status\":\"ACTIVE\"}" "" "200" "PUT /users/{id} (update user)"

# ============================================================================
# EVENT SERVICE
# ============================================================================
echo -e "\n${BLUE}🎫 Testing Event Service${NC}"
echo "============================"

test_endpoint "GET" "/v1/events/ping" "" "" "200" "GET /events/ping"

# Create event
EVENT_DATA="{\"title\":\"API Test Event ${TIMESTAMP}\",\"description\":\"Test event for API testing\",\"eventType\":\"CONFERENCE\",\"venue\":\"Test Venue\",\"address\":\"123 Test St\",\"city\":\"Test City\",\"state\":\"TS\",\"country\":\"US\",\"postalCode\":\"12345\",\"startDate\":\"2030-06-01T10:00:00\",\"endDate\":\"2030-06-01T18:00:00\",\"capacity\":100,\"price\":49.99,\"organizerId\":$USER_ID}"

create_event_response=$(curl -s -X POST "$API_BASE/v1/events" \
    -H "Content-Type: application/json" \
    -d "$EVENT_DATA")

EVENT_ID=$(echo "$create_event_response" | jq -r '.id // empty' 2>/dev/null)

if [ -n "$EVENT_ID" ] && [ "$EVENT_ID" != "null" ]; then
    print_status 0 "POST /events (create event) - Event ID: $EVENT_ID"
    test_endpoint "GET" "/v1/events/$EVENT_ID" "" "" "200" "GET /events/{eventId}"
    test_endpoint "GET" "/v1/events" "" "" "200" "GET /events (list all)"
    test_endpoint "GET" "/v1/events/organizer/$USER_ID" "" "" "200" "GET /events/organizer/{organizerId}"
    test_endpoint "GET" "/v1/events/search?query=API" "" "" "200" "GET /events/search?query=API"
    test_endpoint "GET" "/v1/events/$EVENT_ID/availability" "" "" "200" "GET /events/{eventId}/availability"
    test_endpoint "POST" "/v1/events/$EVENT_ID/publish" "" "" "200" "POST /events/{eventId}/publish"
    test_endpoint "POST" "/v1/events/$EVENT_ID/reserve?quantity=2" "" "" "200" "POST /events/{eventId}/reserve?quantity=2"
    test_endpoint "POST" "/v1/events/$EVENT_ID/release?quantity=1" "" "" "200" "POST /events/{eventId}/release?quantity=1"
    
    # Update event
    UPDATE_DATA="{\"title\":\"Updated API Test Event\",\"description\":\"Updated description\",\"eventType\":\"CONFERENCE\",\"venue\":\"Updated Venue\",\"address\":\"456 Updated St\",\"city\":\"Updated City\",\"state\":\"US\",\"country\":\"US\",\"postalCode\":\"54321\",\"startDate\":\"2030-06-02T10:00:00\",\"endDate\":\"2030-06-02T18:00:00\",\"capacity\":150,\"price\":59.99,\"status\":\"PUBLISHED\"}"
    test_endpoint "PUT" "/v1/events/$EVENT_ID" "$UPDATE_DATA" "" "200" "PUT /events/{eventId} (update event)"
else
    print_status 1 "POST /events (create event) - Failed to create event"
fi

# ============================================================================
# RESERVATION SERVICE
# ============================================================================
echo -e "\n${BLUE}🎟️  Testing Reservation Service${NC}"
echo "===================================="

test_endpoint "GET" "/v1/reservations/ping" "" "" "200" "GET /reservations/ping"

if [ -n "$EVENT_ID" ] && [ "$EVENT_ID" != "null" ]; then
    # Create reservation
    RESERVATION_DATA="{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":2,\"idempotencyKey\":\"resv-api-test-${TIMESTAMP}\"}"
    
    create_reservation_response=$(curl -s -X POST "$API_BASE/v1/reservations" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$RESERVATION_DATA")
    
    RESERVATION_ID=$(echo "$create_reservation_response" | jq -r '.id // empty' 2>/dev/null)
    RESERVATION_ID_STRING=$(echo "$create_reservation_response" | jq -r '.reservationId // empty' 2>/dev/null)
    
    if [ -n "$RESERVATION_ID" ] && [ "$RESERVATION_ID" != "null" ] && [ -n "$RESERVATION_ID_STRING" ] && [ "$RESERVATION_ID_STRING" != "null" ]; then
        print_status 0 "POST /reservations (create reservation) - Reservation ID: $RESERVATION_ID, ReservationId: $RESERVATION_ID_STRING"
        test_endpoint "GET" "/v1/reservations" "" "$TOKEN" "200" "GET /reservations (list all)"
        test_endpoint "GET" "/v1/reservations/$RESERVATION_ID_STRING" "" "$TOKEN" "200" "GET /reservations/{reservationId}"
        test_endpoint "GET" "/v1/reservations/user/$USER_ID" "" "$TOKEN" "200" "GET /reservations/user/{userId}"
        
        # Update reservation
        UPDATE_RESERVATION_DATA="{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":3,\"idempotencyKey\":\"resv-update-${TIMESTAMP}\"}"
        test_endpoint "PUT" "/v1/reservations/$RESERVATION_ID_STRING" "$UPDATE_RESERVATION_DATA" "$TOKEN" "200" "PUT /reservations/{reservationId} (update)"
        test_endpoint "POST" "/v1/reservations/$RESERVATION_ID_STRING/confirm" "" "$TOKEN" "200" "POST /reservations/{reservationId}/confirm"
        test_endpoint "POST" "/v1/reservations/$RESERVATION_ID_STRING/cancel" "" "$TOKEN" "200" "POST /reservations/{reservationId}/cancel"
    else
        print_status 1 "POST /reservations (create reservation) - Failed to create reservation"
    fi
else
    echo -e "${YELLOW}⚠️  Skipping reservation tests - no event available${NC}"
fi

# ============================================================================
# PAYMENT SERVICE
# ============================================================================
echo -e "\n${BLUE}💳 Testing Payment Service${NC}"
echo "============================="

test_endpoint "GET" "/v1/payments/ping" "" "" "200" "GET /payments/ping"

if [ -n "$RESERVATION_ID_STRING" ] && [ "$RESERVATION_ID_STRING" != "null" ]; then
    # Create payment intent
    # Create a new confirmed reservation for payment testing
    PAYMENT_RESERVATION_DATA="{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":1,\"idempotencyKey\":\"pay-resv-${TIMESTAMP}\"}"
    
    payment_reservation_response=$(curl -s -X POST "$API_BASE/v1/reservations" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$PAYMENT_RESERVATION_DATA")
    
    PAYMENT_RESERVATION_ID=$(echo "$payment_reservation_response" | jq -r '.reservationId // empty' 2>/dev/null)
    
    if [ -n "$PAYMENT_RESERVATION_ID" ] && [ "$PAYMENT_RESERVATION_ID" != "null" ]; then
        # Get reservation details to get the correct total price
        reservation_details=$(curl -s -X GET "$API_BASE/v1/reservations/$PAYMENT_RESERVATION_ID" \
            -H "Authorization: Bearer $TOKEN")
        
        RESERVATION_TOTAL=$(echo "$reservation_details" | jq -r '.totalPrice // empty' 2>/dev/null)
        
        # Don't confirm the reservation - payment intent capture requires PENDING state
        if [ -z "$RESERVATION_TOTAL" ] || [ "$RESERVATION_TOTAL" = "null" ]; then
            RESERVATION_TOTAL="49.99"  # Default fallback
        fi
        
        PAYMENT_INTENT_DATA="{\"reservationId\":\"$PAYMENT_RESERVATION_ID\",\"userId\":$USER_ID,\"amount\":$RESERVATION_TOTAL,\"currency\":\"USD\",\"paymentMethod\":\"CARD\",\"description\":\"Ticket purchase\",\"idempotencyKey\":\"pay-intent-${TIMESTAMP}\"}"
        
        create_intent_response=$(curl -s -X POST "$API_BASE/v1/payments/intents" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$PAYMENT_INTENT_DATA")
        
        INTENT_ID=$(echo "$create_intent_response" | jq -r '.id // empty' 2>/dev/null)
        INTENT_ID_STRING=$(echo "$create_intent_response" | jq -r '.intentId // empty' 2>/dev/null)
        
        if [ -n "$INTENT_ID" ] && [ "$INTENT_ID" != "null" ] && [ -n "$INTENT_ID_STRING" ] && [ "$INTENT_ID_STRING" != "null" ]; then
            print_status 0 "POST /payments/intents (create intent) - Intent ID: $INTENT_ID, IntentId: $INTENT_ID_STRING"
            test_endpoint "GET" "/v1/payments/intents/$INTENT_ID_STRING" "" "$TOKEN" "200" "GET /payments/intents/{intentId}"
            test_endpoint "GET" "/v1/payments/intents/user/$USER_ID" "" "$TOKEN" "200" "GET /payments/intents/user/{userId}"
            test_endpoint "POST" "/v1/payments/intents/$INTENT_ID_STRING/capture" "" "$TOKEN" "200" "POST /payments/intents/{intentId}/capture"
        else
            print_status 1 "POST /payments/intents (create intent) - Failed to create payment intent"
            echo "    Response: $create_intent_response"
        fi
    else
        echo -e "${YELLOW}⚠️  Could not create reservation for payment testing${NC}"
    fi
    
    # Legacy payment endpoint (create a new PENDING reservation for this test)
    LEGACY_PAYMENT_RESERVATION_DATA="{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":1,\"idempotencyKey\":\"legacy-pay-resv-${TIMESTAMP}\"}"
    
    legacy_payment_reservation_response=$(curl -s -X POST "$API_BASE/v1/reservations" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$LEGACY_PAYMENT_RESERVATION_DATA")
    
    LEGACY_PAYMENT_RESERVATION_ID=$(echo "$legacy_payment_reservation_response" | jq -r '.reservationId // empty' 2>/dev/null)
    LEGACY_RESERVATION_TOTAL=$(echo "$legacy_payment_reservation_response" | jq -r '.totalPrice // empty' 2>/dev/null)
    
    if [ -n "$LEGACY_PAYMENT_RESERVATION_ID" ] && [ "$LEGACY_PAYMENT_RESERVATION_ID" != "null" ]; then
        if [ -z "$LEGACY_RESERVATION_TOTAL" ] || [ "$LEGACY_RESERVATION_TOTAL" = "null" ]; then
            LEGACY_RESERVATION_TOTAL="49.99"  # Default fallback
        fi
        PAYMENT_DATA="{\"reservationId\":\"$LEGACY_PAYMENT_RESERVATION_ID\",\"userId\":$USER_ID,\"amount\":$LEGACY_RESERVATION_TOTAL,\"currency\":\"USD\",\"paymentMethod\":\"CARD\",\"description\":\"Ticket purchase\",\"idempotencyKey\":\"pay-legacy-${TIMESTAMP}\"}"
        
        create_payment_response=$(curl -s -X POST "$API_BASE/v1/payments" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d "$PAYMENT_DATA")
        
        PAYMENT_ID=$(echo "$create_payment_response" | jq -r '.id // empty' 2>/dev/null)
        PAYMENT_ID_STRING=$(echo "$create_payment_response" | jq -r '.paymentId // empty' 2>/dev/null)
        
        if [ -n "$PAYMENT_ID" ] && [ "$PAYMENT_ID" != "null" ] && [ -n "$PAYMENT_ID_STRING" ] && [ "$PAYMENT_ID_STRING" != "null" ]; then
            print_status 0 "POST /payments (legacy endpoint) - Payment ID: $PAYMENT_ID, PaymentId: $PAYMENT_ID_STRING"
            test_endpoint "GET" "/v1/payments" "" "$TOKEN" "200" "GET /payments (list all)"
            test_endpoint "GET" "/v1/payments/$PAYMENT_ID_STRING" "" "$TOKEN" "200" "GET /payments/{paymentId}"
            test_endpoint "GET" "/v1/payments/user/$USER_ID" "" "$TOKEN" "200" "GET /payments/user/{userId}"
            test_endpoint "PUT" "/v1/payments/$PAYMENT_ID_STRING/status" "{\"status\":\"COMPLETED\"}" "$TOKEN" "200" "PUT /payments/{paymentId}/status"
            test_endpoint "POST" "/v1/payments/$PAYMENT_ID_STRING/process" "" "$TOKEN" "200" "POST /payments/{paymentId}/process"
        else
            print_status 1 "POST /payments (legacy endpoint) - Failed to create payment"
            echo "    Response: $create_payment_response"
        fi
    fi
    
    test_endpoint "POST" "/v1/payments/cleanup" "" "$TOKEN" "200" "POST /payments/cleanup"
else
    echo -e "${YELLOW}⚠️  Skipping payment tests - no reservation available${NC}"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo -e "${CYAN}📊 Test Summary${NC}"
echo "===================================="
echo -e "Total Tests: ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}🎉 All API tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please review the output above.${NC}"
    exit 1
fi

