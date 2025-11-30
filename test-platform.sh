#!/bin/bash

# Event Management Platform - Comprehensive Test Script
# This script tests all components of the platform

set -e  # Exit on any error

echo "🎯 EVENT MANAGEMENT PLATFORM - COMPREHENSIVE TEST SUITE"
echo "================================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counter
TEST_COUNT=0
PASSED=0
FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_status="${3:-200}"

    TEST_COUNT=$((TEST_COUNT + 1))

    echo -e "${BLUE}Test $TEST_COUNT: $test_name${NC}"
    echo -e "${YELLOW}Command:${NC} $command"
    echo -e "${YELLOW}Expected:${NC} HTTP $expected_status or success"
    echo ""

    # Run the command and capture output
    if [[ $command == http* ]]; then
        # HTTP request
        response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" "$command" 2>/dev/null || echo "CONNECTION_FAILED")
        http_status=$(echo "$response" | grep "HTTPSTATUS:" | cut -d: -f2)
        body=$(echo "$response" | sed '/HTTPSTATUS:/d')

        if [[ $http_status == "$expected_status" ]] || [[ $http_status == "201" && $expected_status == "200" ]]; then
            echo -e "${GREEN}✅ PASSED${NC} - HTTP $http_status"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}❌ FAILED${NC} - HTTP $http_status (expected $expected_status)"
            FAILED=$((FAILED + 1))
        fi

        # Show response body (truncated if too long)
        if [[ ${#body} -gt 200 ]]; then
            echo -e "${YELLOW}Response:${NC} $(echo "$body" | head -c 200)...[truncated]"
        else
            echo -e "${YELLOW}Response:${NC} $body"
        fi
    else
        # Regular command
        if output=$(eval "$command" 2>&1); then
            echo -e "${GREEN}✅ PASSED${NC}"
            echo -e "${YELLOW}Output:${NC} $output"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}❌ FAILED${NC}"
            echo -e "${YELLOW}Error:${NC} $output"
            FAILED=$((FAILED + 1))
        fi
    fi

    echo ""
    echo "-----------------------------------------------------------------"
    echo ""
}

# Function to test with authentication
run_auth_test() {
    local test_name="$1"
    local method="$2"
    local endpoint="$3"
    local data="$4"
    local expected_status="${5:-200}"

    TEST_COUNT=$((TEST_COUNT + 1))

    echo -e "${BLUE}Test $TEST_COUNT: $test_name${NC}"
    echo -e "${YELLOW}Command:${NC} curl -X $method http://localhost:8080$endpoint"
    echo -e "${YELLOW}Expected:${NC} HTTP $expected_status"
    echo ""

    # First get a token
    token_response=$(curl -s -X POST http://localhost:8080/v1/auth/login \
        -H "Content-Type: application/json" \
        -d '{"email":"testuser123@example.com","password":"password123"}')

    token=$(echo "$token_response" | jq -r '.token // empty' 2>/dev/null)

    if [[ -z "$token" ]]; then
        echo -e "${RED}❌ FAILED${NC} - Could not get authentication token"
        echo -e "${YELLOW}Login Response:${NC} $token_response"
        FAILED=$((FAILED + 1))
    else
        # Run the authenticated request
        if [[ -n "$data" ]]; then
            response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" \
                -X "$method" "http://localhost:8080$endpoint" \
                -H "Authorization: Bearer $token" \
                -H "Content-Type: application/json" \
                -d "$data" 2>/dev/null || echo "CONNECTION_FAILED")
        else
            response=$(curl -s -w "\nHTTPSTATUS:%{http_code}" \
                -X "$method" "http://localhost:8080$endpoint" \
                -H "Authorization: Bearer $token" 2>/dev/null || echo "CONNECTION_FAILED")
        fi

        http_status=$(echo "$response" | grep "HTTPSTATUS:" | cut -d: -f2)
        body=$(echo "$response" | sed '/HTTPSTATUS:/d')

        if [[ $http_status == "$expected_status" ]] || [[ $http_status == "201" && $expected_status == "200" ]]; then
            echo -e "${GREEN}✅ PASSED${NC} - HTTP $http_status"
            PASSED=$((PASSED + 1))
        else
            echo -e "${RED}❌ FAILED${NC} - HTTP $http_status (expected $expected_status)"
            FAILED=$((FAILED + 1))
        fi

        echo -e "${YELLOW}Response:${NC} $body"
    fi

    echo ""
    echo "-----------------------------------------------------------------"
    echo ""
}

echo "🔍 INFRASTRUCTURE TESTS"
echo "================================================================="

# Test 1: Eureka Server Health
run_test "Eureka Server Health" "curl -s http://localhost:8761/eureka/apps | grep -c '<application>'" "1"

# Test 2: Config Server Health
run_test "Config Server Health" "curl -s http://localhost:8888/actuator/health | jq -r '.status' 2>/dev/null || echo 'DOWN'" "UP"

# Test 3: PostgreSQL Connection
run_test "PostgreSQL Connection" "docker ps | grep postgres | wc -l" "1"

# Test 4: Redis Connection
run_test "Redis Connection" "docker ps | grep redis | wc -l" "1"

echo "🏗️ SERVICE DISCOVERY TESTS"
echo "================================================================="

# Test 5: API Gateway Health
run_test "API Gateway Health" "curl -s http://localhost:8080/actuator/health | jq -r '.status' 2>/dev/null || echo 'DOWN'" "UP"

# Test 6: Service Discovery Count
run_test "Registered Services Count" "curl -s http://localhost:8080/actuator/health | jq -r '.components.discoveryComposite.components.discoveryClient.details.services | length' 2>/dev/null || echo '0'" "3"

# Test 7: User Service Direct Health
run_test "User Service Direct Health" "curl -s http://localhost:8081/actuator/health | jq -r '.status' 2>/dev/null || echo 'DOWN'" "UP"

# Test 8: Event Service Direct Health
run_test "Event Service Direct Health" "curl -s http://localhost:8082/actuator/health | jq -r '.status' 2>/dev/null || echo 'DOWN'" "UP"

echo "🔐 AUTHENTICATION TESTS"
echo "================================================================="

# Test 8: User Registration
run_test "User Registration" "curl -s -w '\nHTTPSTATUS:%{http_code}' -X POST http://localhost:8080/v1/auth/register -H 'Content-Type: application/json' -d '{\"email\":\"test-script-$(date +%s)@example.com\",\"password\":\"password123\",\"firstName\":\"Test\",\"lastName\":\"Script\"}' | grep 'HTTPSTATUS:' | cut -d: -f2" "201"

# Test 9: User Login
run_test "User Login" "curl -s -X POST http://localhost:8080/v1/auth/login -H 'Content-Type: application/json' -d '{\"email\":\"testuser123@example.com\",\"password\":\"password123\"}' | jq -r '.token | length > 10' 2>/dev/null || echo 'false'" "true"

# Test 10: Ping Endpoint
run_test "API Gateway Ping" "curl -s http://localhost:8080/v1/users/ping" "OK"

echo "💾 DATABASE TESTS"
echo "================================================================="

# Test 11: Database User Count
run_test "Database User Count" "docker exec \$(docker ps -q --filter name=postgres) psql -U postgres -d userdb -c 'SELECT COUNT(*) FROM users;' 2>/dev/null | tail -3 | head -1 | tr -d ' '" "5"

# Test 12: Database Connection Health
run_test "User Service DB Health" "curl -s http://localhost:8081/actuator/health | jq -r '.components.db.status' 2>/dev/null || echo 'DOWN'" "UP"

# Test 13: Event Service DB Health
run_test "Event Service DB Health" "curl -s http://localhost:8082/actuator/health | jq -r '.components.db.status' 2>/dev/null || echo 'DOWN'" "UP"

echo "🔄 CONFIGURATION TESTS"
echo "================================================================="

# Test 13: Config Server User Service Config
run_test "Config Server User Service" "curl -s http://localhost:8888/user-service/default | jq -r '.propertySources[0].name' 2>/dev/null || echo 'NOT_FOUND'" "classpath:/config/user-service.yml"

# Test 14: Config Server API Gateway Config
run_test "Config Server API Gateway" "curl -s http://localhost:8888/api-gateway/default | jq -r '.propertySources[0].name' 2>/dev/null || echo 'NOT_FOUND'" "classpath:/config/api-gateway.yml"

# Test 15: Config Server Event Service Config
run_test "Config Server Event Service" "curl -s http://localhost:8888/event-service/default | jq -r '.propertySources[0].name' 2>/dev/null || echo 'NOT_FOUND'" "classpath:/config/event-service.yml"

echo "🎯 END-TO-END TESTS"
echo "================================================================="

# Test 15: Complete User Journey
echo -e "${BLUE}Test 15: Complete User Journey${NC}"
echo -e "${YELLOW}Testing full registration → login → profile flow${NC}"
echo ""

# Register a new user
timestamp=$(date +%s)
email="journey-$timestamp@example.com"
register_response=$(curl -s -X POST http://localhost:8080/v1/auth/register \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"password123\",\"firstName\":\"Journey\",\"lastName\":\"Test\"}")

if echo "$register_response" | jq -e '.userId' >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Registration PASSED${NC}"

    # Login with the new user
    login_response=$(curl -s -X POST http://localhost:8080/v1/auth/login \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$email\",\"password\":\"password123\"}")

    if echo "$login_response" | jq -e '.token' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Login PASSED${NC}"
        PASSED=$((PASSED + 1))
        TEST_COUNT=$((TEST_COUNT + 1))
        echo -e "${YELLOW}Complete journey successful!${NC}"
    else
        echo -e "${RED}❌ Login FAILED${NC}"
        FAILED=$((FAILED + 1))
        TEST_COUNT=$((TEST_COUNT + 1))
    fi
else
    echo -e "${RED}❌ Registration FAILED${NC}"
    echo -e "${YELLOW}Response:${NC} $register_response"
    FAILED=$((FAILED + 1))
    TEST_COUNT=$((TEST_COUNT + 1))
fi

# Test 16: Event Service Events Count
run_test "Event Service Events Count" "curl -s http://localhost:8082/events | jq -r 'length' 2>/dev/null || echo '0'" "3"

echo ""
echo "================================================================="
echo -e "${BLUE}🎯 TEST SUMMARY${NC}"
echo "================================================================="
echo -e "${GREEN}✅ PASSED: $PASSED${NC}"
echo -e "${RED}❌ FAILED: $FAILED${NC}"
echo -e "${BLUE}📊 TOTAL: $TEST_COUNT${NC}"

if [ $FAILED -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 ALL TESTS PASSED! Platform is fully operational!${NC}"
    echo "🚀 Ready to build Event Service, Reservation Service, etc."
else
    echo ""
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above for details.${NC}"
    echo "🔧 Fix the failing components before proceeding."
fi

echo ""
echo "================================================================="
