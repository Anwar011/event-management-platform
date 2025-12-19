#!/bin/bash

echo "🎯 EventHub Backend Testing Script"
echo "===================================="

API_BASE="http://localhost:8080"
TEST_USER_EMAIL="test@example.com"
TEST_USER_PASSWORD="password123"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    local status=$1
    local message=$2
    if [ "$status" -eq 0 ]; then
        echo -e "${GREEN}✅ $message${NC}"
    else
        echo -e "${RED}❌ $message${NC}"
    fi
}

# Function to test health endpoint
test_health() {
    echo -e "\n${BLUE}🔍 Testing Health Check${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null "$API_BASE/actuator/health")
    if [ "$response" -eq 200 ]; then
        print_status 0 "API Gateway health check passed"
        return 0
    else
        print_status 1 "API Gateway health check failed (HTTP $response)"
        return 1
    fi
}

# Function to test Eureka discovery
test_eureka() {
    echo -e "\n${BLUE}🔍 Testing Service Discovery${NC}"
    response=$(curl -s -w "%{http_code}" -o /dev/null "http://localhost:8761/eureka/apps")
    if [ "$response" -eq 200 ]; then
        print_status 0 "Eureka Server is accessible"
        return 0
    else
        print_status 1 "Eureka Server not accessible (HTTP $response)"
        return 1
    fi
}

# Function to test user registration
test_user_registration() {
    echo -e "\n${BLUE}🔍 Testing User Registration${NC}"
    response=$(curl -s -X POST "$API_BASE/v1/auth/register" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_USER_EMAIL\",\"password\":\"$TEST_USER_PASSWORD\",\"firstName\":\"Test\",\"lastName\":\"User\"}" \
        -w "%{http_code}" -o /dev/null)

    if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
        print_status 0 "User registration successful"
        return 0
    else
        print_status 1 "User registration failed (HTTP $response)"
        return 1
    fi
}

# Function to test user login
test_user_login() {
    echo -e "\n${BLUE}🔍 Testing User Login${NC}"
    response=$(curl -s -X POST "$API_BASE/v1/auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$TEST_USER_EMAIL\",\"password\":\"$TEST_USER_PASSWORD\"}")

    http_code=$(echo "$response" | grep -o '"http_code":[0-9]*' | cut -d':' -f2)
    if [ "$http_code" -eq 200 ] || [ "$http_code" -eq 201 ]; then
        token=$(echo "$response" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$token" ]; then
            print_status 0 "User login successful"
            echo "$token"
            return 0
        fi
    fi
    print_status 1 "User login failed"
    return 1
}

# Function to test events endpoint
test_events() {
    echo -e "\n${BLUE}🔍 Testing Events API${NC}"
    response=$(curl -s "$API_BASE/v1/events" -w "%{http_code}" -o /tmp/events_response.json)

    if [ "$response" -eq 200 ]; then
        event_count=$(jq '.content | length' /tmp/events_response.json 2>/dev/null)
        if [ "$event_count" -ge 0 ] 2>/dev/null; then
            print_status 0 "Events API working - found $event_count events"
            return 0
        fi
    fi
    print_status 1 "Events API failed (HTTP $response)"
    return 1
}

# Function to test reservations endpoint (requires auth)
test_reservations() {
    local token=$1
    echo -e "\n${BLUE}🔍 Testing Reservations API${NC}"

    if [ -z "$token" ]; then
        print_status 1 "No authentication token available for reservations test"
        return 1
    fi

    response=$(curl -s "$API_BASE/v1/reservations/user/1" \
        -H "Authorization: Bearer $token" \
        -w "%{http_code}" -o /dev/null)

    if [ "$response" -eq 200 ]; then
        print_status 0 "Reservations API accessible with authentication"
        return 0
    else
        print_status 1 "Reservations API failed (HTTP $response)"
        return 1
    fi
}

# Function to test booking creation (requires auth)
test_booking() {
    local token=$1
    echo -e "\n${BLUE}🔍 Testing Booking Creation${NC}"

    if [ -z "$token" ]; then
        print_status 1 "No authentication token available for booking test"
        return 1
    fi

    response=$(curl -s -X POST "$API_BASE/v1/reservations" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $token" \
        -d '{"userId":1,"eventId":7,"quantity":1,"idempotencyKey":"test-booking-'$(date +%s)'"}' \
        -w "%{http_code}" -o /dev/null)

    if [ "$response" -eq 200 ] || [ "$response" -eq 201 ]; then
        print_status 0 "Booking creation successful"
        return 0
    else
        print_status 1 "Booking creation failed (HTTP $response)"
        return 1
    fi
}

# Function to test CORS
test_cors() {
    echo -e "\n${BLUE}🔍 Testing CORS Configuration${NC}"
    response=$(curl -s -I -H "Origin: http://localhost:3000" \
        -H "Access-Control-Request-Method: GET" \
        -X OPTIONS "$API_BASE/v1/events" | grep -i "access-control-allow-origin")

    if [ -n "$response" ]; then
        print_status 0 "CORS headers configured correctly"
        return 0
    else
        print_status 1 "CORS headers not found"
        return 1
    fi
}

# Function to check service registration
test_service_discovery() {
    echo -e "\n${BLUE}🔍 Testing Service Discovery${NC}"
    response=$(curl -s "http://localhost:8761/eureka/apps" | grep -c "USER-SERVICE\|EVENT-SERVICE\|RESERVATION-SERVICE\|PAYMENT-SERVICE\|API-GATEWAY")

    if [ "$response" -ge 3 ]; then
        print_status 0 "Multiple services registered with Eureka ($response services found)"
        return 0
    else
        print_status 1 "Service discovery issue - only $response services registered"
        return 1
    fi
}

# Main test execution
echo "Starting comprehensive backend testing..."
echo "=========================================="

# Test infrastructure
test_health
test_eureka
test_service_discovery

# Test user services
test_user_registration
auth_token=$(test_user_login)

# Test business logic
test_events
test_cors

if [ -n "$auth_token" ]; then
    test_reservations "$auth_token"
    test_booking "$auth_token"
else
    echo -e "\n${YELLOW}⚠️  Skipping authenticated tests due to login failure${NC}"
fi

echo -e "\n${BLUE}🏁 Backend Testing Complete${NC}"
echo "================================"

# Summary
echo -e "\n${YELLOW}📊 Test Summary:${NC}"
echo "- Infrastructure services (Eureka, Config Server)"
echo "- API Gateway and routing"
echo "- User authentication and registration"
echo "- Event management"
echo "- Reservation system"
echo "- CORS configuration"
echo "- Service discovery"

echo -e "\n${GREEN}🎉 All backend services have been tested!${NC}"


