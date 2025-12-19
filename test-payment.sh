#!/bin/bash

echo "💳 Payment Service Testing Script"
echo "=================================="
echo ""

API_BASE="http://localhost:8080"
TIMESTAMP=$(date +%s)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "\n${CYAN}📋 Step $1: $2${NC}"
    echo "----------------------------------------"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Step 1: Create a test user and login
print_step "1" "Setting up test user and authentication"

TEST_EMAIL="payment-test-${TIMESTAMP}@example.com"
TEST_PASSWORD="TestPassword123"

# Register user
register_response=$(curl -s -X POST "$API_BASE/v1/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\",\"firstName\":\"Payment\",\"lastName\":\"Test\"}")

USER_ID=$(echo "$register_response" | jq -r '.userId // empty' 2>/dev/null)

# Login to get token
login_response=$(curl -s -X POST "$API_BASE/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$TEST_EMAIL\",\"password\":\"$TEST_PASSWORD\"}")

TOKEN=$(echo "$login_response" | jq -r '.token // empty' 2>/dev/null)

if [ -z "$TOKEN" ] || [ -z "$USER_ID" ]; then
    print_error "Failed to create user or get authentication token"
    exit 1
fi

print_success "User created: $TEST_EMAIL (ID: $USER_ID)"
print_success "Authentication token obtained"

# Step 2: Create an event
print_step "2" "Creating a test event"

EVENT_DATA="{\"title\":\"Payment Test Event ${TIMESTAMP}\",\"description\":\"Event for payment testing\",\"eventType\":\"CONFERENCE\",\"venue\":\"Test Venue\",\"address\":\"123 Test St\",\"city\":\"Test City\",\"state\":\"TS\",\"country\":\"US\",\"postalCode\":\"12345\",\"startDate\":\"2030-07-01T10:00:00\",\"endDate\":\"2030-07-01T18:00:00\",\"capacity\":100,\"price\":99.99,\"organizerId\":$USER_ID}"

create_event_response=$(curl -s -X POST "$API_BASE/v1/events" \
    -H "Content-Type: application/json" \
    -d "$EVENT_DATA")

EVENT_ID=$(echo "$create_event_response" | jq -r '.id // empty' 2>/dev/null)

if [ -z "$EVENT_ID" ] || [ "$EVENT_ID" = "null" ]; then
    print_error "Failed to create event"
    exit 1
fi

print_success "Event created: ID $EVENT_ID"

# Publish the event
curl -s -X POST "$API_BASE/v1/events/$EVENT_ID/publish" > /dev/null
print_success "Event published"

# Step 3: Create a reservation
print_step "3" "Creating a reservation"

RESERVATION_DATA="{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":2,\"idempotencyKey\":\"payment-test-resv-${TIMESTAMP}\"}"

create_reservation_response=$(curl -s -X POST "$API_BASE/v1/reservations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$RESERVATION_DATA")

RESERVATION_ID=$(echo "$create_reservation_response" | jq -r '.reservationId // empty' 2>/dev/null)
RESERVATION_TOTAL=$(echo "$create_reservation_response" | jq -r '.totalPrice // empty' 2>/dev/null)

if [ -z "$RESERVATION_ID" ] || [ "$RESERVATION_ID" = "null" ]; then
    print_error "Failed to create reservation"
    exit 1
fi

print_success "Reservation created: $RESERVATION_ID"
print_info "Reservation total: \$$RESERVATION_TOTAL"
echo "$create_reservation_response" | jq '.' 2>/dev/null

# Step 4: Test Payment Intent Flow (Modern API)
print_step "4" "Testing Payment Intent API (Modern Flow)"

echo -e "\n${YELLOW}4.1: Create Payment Intent${NC}"
PAYMENT_INTENT_DATA="{\"reservationId\":\"$RESERVATION_ID\",\"userId\":$USER_ID,\"amount\":$RESERVATION_TOTAL,\"currency\":\"USD\",\"paymentMethod\":\"CARD\",\"description\":\"Ticket purchase for event $EVENT_ID\",\"idempotencyKey\":\"pay-intent-${TIMESTAMP}\"}"

create_intent_response=$(curl -s -X POST "$API_BASE/v1/payments/intents" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$PAYMENT_INTENT_DATA")

INTENT_ID=$(echo "$create_intent_response" | jq -r '.intentId // empty' 2>/dev/null)
INTENT_NUMERIC_ID=$(echo "$create_intent_response" | jq -r '.id // empty' 2>/dev/null)

if [ -n "$INTENT_ID" ] && [ "$INTENT_ID" != "null" ]; then
    print_success "Payment Intent created: $INTENT_ID"
    echo "$create_intent_response" | jq '.' 2>/dev/null
else
    print_error "Failed to create payment intent"
    echo "Response: $create_intent_response"
    exit 1
fi

echo -e "\n${YELLOW}4.2: Get Payment Intent${NC}"
get_intent_response=$(curl -s -X GET "$API_BASE/v1/payments/intents/$INTENT_ID" \
    -H "Authorization: Bearer $TOKEN")

if echo "$get_intent_response" | jq -e '.intentId' > /dev/null 2>&1; then
    print_success "Payment Intent retrieved successfully"
    echo "$get_intent_response" | jq '.' 2>/dev/null
else
    print_error "Failed to retrieve payment intent"
    echo "Response: $get_intent_response"
fi

echo -e "\n${YELLOW}4.3: Get User's Payment Intents${NC}"
user_intents_response=$(curl -s -X GET "$API_BASE/v1/payments/intents/user/$USER_ID" \
    -H "Authorization: Bearer $TOKEN")

if echo "$user_intents_response" | jq -e '.[]' > /dev/null 2>&1; then
    print_success "User payment intents retrieved"
    echo "$user_intents_response" | jq '.' 2>/dev/null | head -20
else
    print_error "Failed to retrieve user payment intents"
fi

echo -e "\n${YELLOW}4.4: Capture Payment (Process Payment)${NC}"
print_info "Note: Reservation must be in PENDING state for capture to work"
print_info "The capture will process the payment and confirm the reservation"

capture_response=$(curl -s -X POST "$API_BASE/v1/payments/intents/$INTENT_ID/capture" \
    -H "Authorization: Bearer $TOKEN")

PAYMENT_ID=$(echo "$capture_response" | jq -r '.paymentId // empty' 2>/dev/null)

if [ -n "$PAYMENT_ID" ] && [ "$PAYMENT_ID" != "null" ]; then
    print_success "Payment captured successfully: $PAYMENT_ID"
    echo "$capture_response" | jq '.' 2>/dev/null
else
    print_error "Failed to capture payment"
    echo "Response: $capture_response"
    print_info "This might fail if reservation is already confirmed"
fi

# Step 5: Test Legacy Payment API
print_step "5" "Testing Legacy Payment API"

echo -e "\n${YELLOW}5.1: Create a new reservation for legacy payment${NC}"
LEGACY_RESERVATION_DATA="{\"userId\":$USER_ID,\"eventId\":$EVENT_ID,\"quantity\":1,\"idempotencyKey\":\"legacy-pay-resv-${TIMESTAMP}\"}"

legacy_reservation_response=$(curl -s -X POST "$API_BASE/v1/reservations" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "$LEGACY_RESERVATION_DATA")

LEGACY_RESERVATION_ID=$(echo "$legacy_reservation_response" | jq -r '.reservationId // empty' 2>/dev/null)
LEGACY_RESERVATION_TOTAL=$(echo "$legacy_reservation_response" | jq -r '.totalPrice // empty' 2>/dev/null)

if [ -n "$LEGACY_RESERVATION_ID" ] && [ "$LEGACY_RESERVATION_ID" != "null" ]; then
    print_success "Reservation created for legacy payment: $LEGACY_RESERVATION_ID"
    
    echo -e "\n${YELLOW}5.2: Create Payment (Legacy Endpoint)${NC}"
    print_info "Note: Reservation must be in PENDING state (not confirmed)"
    
    LEGACY_PAYMENT_DATA="{\"reservationId\":\"$LEGACY_RESERVATION_ID\",\"userId\":$USER_ID,\"amount\":$LEGACY_RESERVATION_TOTAL,\"currency\":\"USD\",\"paymentMethod\":\"CARD\",\"description\":\"Legacy payment for event $EVENT_ID\",\"idempotencyKey\":\"legacy-pay-${TIMESTAMP}\"}"
    
    legacy_payment_response=$(curl -s -X POST "$API_BASE/v1/payments" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "$LEGACY_PAYMENT_DATA")
    
    LEGACY_PAYMENT_ID=$(echo "$legacy_payment_response" | jq -r '.paymentId // empty' 2>/dev/null)
    
    if [ -n "$LEGACY_PAYMENT_ID" ] && [ "$LEGACY_PAYMENT_ID" != "null" ]; then
        print_success "Legacy payment created: $LEGACY_PAYMENT_ID"
        echo "$legacy_payment_response" | jq '.' 2>/dev/null
        
        echo -e "\n${YELLOW}5.3: Get Payment Details${NC}"
        get_payment_response=$(curl -s -X GET "$API_BASE/v1/payments/$LEGACY_PAYMENT_ID" \
            -H "Authorization: Bearer $TOKEN")
        
        if echo "$get_payment_response" | jq -e '.paymentId' > /dev/null 2>&1; then
            print_success "Payment retrieved successfully"
            echo "$get_payment_response" | jq '.' 2>/dev/null
        else
            print_error "Failed to retrieve payment"
        fi
        
        echo -e "\n${YELLOW}5.4: Get All Payments${NC}"
        all_payments_response=$(curl -s -X GET "$API_BASE/v1/payments" \
            -H "Authorization: Bearer $TOKEN")
        
        if echo "$all_payments_response" | jq -e '.[]' > /dev/null 2>&1; then
            print_success "All payments retrieved"
            echo "$all_payments_response" | jq '.' 2>/dev/null | head -30
        fi
        
        echo -e "\n${YELLOW}5.5: Get User's Payments${NC}"
        user_payments_response=$(curl -s -X GET "$API_BASE/v1/payments/user/$USER_ID" \
            -H "Authorization: Bearer $TOKEN")
        
        if echo "$user_payments_response" | jq -e '.[]' > /dev/null 2>&1; then
            print_success "User payments retrieved"
            echo "$user_payments_response" | jq '.' 2>/dev/null | head -30
        fi
        
        echo -e "\n${YELLOW}5.6: Update Payment Status${NC}"
        update_status_response=$(curl -s -X PUT "$API_BASE/v1/payments/$LEGACY_PAYMENT_ID/status" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $TOKEN" \
            -d '{"status":"COMPLETED"}')
        
        if echo "$update_status_response" | jq -e '.status' > /dev/null 2>&1; then
            print_success "Payment status updated"
            echo "$update_status_response" | jq '.' 2>/dev/null
        else
            print_error "Failed to update payment status"
        fi
        
        echo -e "\n${YELLOW}5.7: Process Payment${NC}"
        process_payment_response=$(curl -s -X POST "$API_BASE/v1/payments/$LEGACY_PAYMENT_ID/process" \
            -H "Authorization: Bearer $TOKEN")
        
        if echo "$process_payment_response" | jq -e '.status' > /dev/null 2>&1; then
            print_success "Payment processed"
            echo "$process_payment_response" | jq '.' 2>/dev/null
        else
            print_error "Failed to process payment"
        fi
    else
        print_error "Failed to create legacy payment"
        echo "Response: $legacy_payment_response"
    fi
else
    print_error "Failed to create reservation for legacy payment"
fi

# Step 6: Test Payment Service Health
print_step "6" "Testing Payment Service Health"

ping_response=$(curl -s -X GET "$API_BASE/v1/payments/ping")
if echo "$ping_response" | jq -e '.status' > /dev/null 2>&1; then
    print_success "Payment service is healthy"
    echo "$ping_response" | jq '.' 2>/dev/null
else
    print_error "Payment service health check failed"
fi

# Step 7: Cleanup (optional)
print_step "7" "Cleanup (Optional)"

read -p "Do you want to run payment cleanup? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    cleanup_response=$(curl -s -X POST "$API_BASE/v1/payments/cleanup" \
        -H "Authorization: Bearer $TOKEN")
    print_success "Cleanup completed"
    echo "$cleanup_response" | jq '.' 2>/dev/null
fi

echo -e "\n${GREEN}🎉 Payment Testing Complete!${NC}"
echo "=================================="
echo ""
echo "Summary:"
echo "  - User ID: $USER_ID"
echo "  - Event ID: $EVENT_ID"
echo "  - Reservation ID: $RESERVATION_ID"
if [ -n "$INTENT_ID" ]; then
    echo "  - Payment Intent ID: $INTENT_ID"
fi
if [ -n "$PAYMENT_ID" ]; then
    echo "  - Payment ID: $PAYMENT_ID"
fi
if [ -n "$LEGACY_PAYMENT_ID" ]; then
    echo "  - Legacy Payment ID: $LEGACY_PAYMENT_ID"
fi
echo ""

